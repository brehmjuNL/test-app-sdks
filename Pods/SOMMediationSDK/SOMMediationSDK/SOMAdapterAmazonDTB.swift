//
//  SOIAdapterAmazonDTP.swift
//  TestAppiOS
//
//  Created by brehmjuNL on 2018-07-04.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//
import Foundation
import GoogleMobileAds
import DTBiOSSDK

@objc public class SOMAdapterAmazonDTB: SOMAdapter {

    let KEY_ADUNIT = "adUnit"
    let KEY_APPKEY = "appKey"
    let KEY_SLOTID = "slotId"
    let KEY_MINPRICEPOINT = "minPricePoint"
    let KEY_DELIVER = "deliver"
    let KEY_SHOWROOM = "showroom"

    override func processAdRequest(){
        if consentStringIsZero() { // Skip Amazon network if user has opted out of personalized Ads
            proceedWithOtherNetwork(GADErrorCode.internalError, message: "IAB consent string is zero.")
        } else {
            buildDTBRequest()
            loadDTBRecommendation()
        }
    }
    
    override func setLogTag(_ logSize: GADAdSize){
        logTag = String(format: "SOMAdapterAmazonDTB %ix%i", Int(size.size.width), Int(size.size.height))
    }
    
    override func setKeysToExtractFromParameterString(){
        requiredKeys = [KEY_ADUNIT, KEY_APPKEY, KEY_SLOTID]
        optionalKeys = [KEY_DELIVER, KEY_SHOWROOM, KEY_MINPRICEPOINT]
    }

    func buildDTBRequest(){
        let sharedInstances = DTBAds.sharedInstance()
        SOMAdapterLogger.log(String(format: "%@: DTB SDK version %@", logTag, DTBAds.version()))
        
        sharedInstances.setAppKey(extractedParameters[KEY_APPKEY]!)
        sharedInstances.useGeoLocation = true
        sharedInstances.useSecureConnection = true
        
        if(isDebugEnabled()){ // boolean
            SOMAdapterLogger.log(String(format: "%@: Enable DTB logging.", logTag))
            sharedInstances.setLogLevel(DTBLogLevelAll)
        }
        
        if(isTestModeEnabled()){ // condition in method
            SOMAdapterLogger.log(String(format: "%@: Enable DTB test mode.", logTag))
            sharedInstances.testMode = true
        }
    }
    
    func isDebugEnabled() -> Bool {
        return debug > 0
    }
    
    func isTestModeEnabled() -> Bool {
        return testing
            || debug == 2
    }
    
    func loadDTBRecommendation(){
        // Object with size and slot id
        let sizeDTB = DTBAdSize(
            bannerAdSizeWithWidth: Int(size.size.width),
            height: Int(size.size.height),
            andSlotUUID: extractedParameters[KEY_SLOTID]!)
        // Request Reccomendation
        let DTBloader = DTBAdLoader()
        DTBloader.setAdSizes([sizeDTB as Any])
        
        SOMAdapterLogger.log(String(format: "%@: Request DTB Reccomendation...", logTag))
        DTBloader.loadAd(self)
    }

    func loadAdInDFP(targeting: [AnyHashable : Any]!){
        // Define custom targeting
        var customTargeting = targeting
        if extractedParameters[KEY_DELIVER] != nil {
            customTargeting![KEY_DELIVER] = extractedParameters[KEY_DELIVER]
        }
        if isShowroomEnabled() {
            customTargeting![KEY_SHOWROOM] = extractedParameters[KEY_SHOWROOM]
            SOMAdapterLogger.log(String(format: "%@: Showroom enabled, add key-value >showroom=%@< to custom targeting.", logTag, extractedParameters[KEY_SHOWROOM]!))
        }
        let requestDFPAd = buildDFPRequest(adUnit: extractedParameters[KEY_ADUNIT]!,
                                           customTargeting: customTargeting)
        loadDFPAd(requestDFPAd)
    }
    
    func isShowroomEnabled() -> Bool {
        return extractedParameters[KEY_SHOWROOM] != nil
            && debug > 0
    }

    func pricePointIsHigherThanMinimumPricePoint(minPricePointString: String!, pricePointString: String!) -> Bool {
        if minPricePointString == nil {
            SOMAdapterLogger.log(String(format: "%@: No minimum price point set.", logTag))
            return true // get Ad anyways
        }
        if pricePointString == nil {
            SOMAdapterLogger.log(String(format: "%@: No price point set.", logTag))
            return true // get Ad anyways
        }
        if let minPricePoint = NumberFormatter().number(from: minPricePointString) {
            let ppArray = pricePointString.components(separatedBy: "p")
            if let pricePoint = NumberFormatter().number(from: ppArray[1]) {
                SOMAdapterLogger.log(String(format: "%@: Extracted values pricePoint=%i and minPricePoint=%i", logTag, pricePoint.intValue, minPricePoint.intValue))
                if pricePoint.intValue < minPricePoint.intValue {
                    SOMAdapterLogger.log(String(format: "%@: Price point lower then min price point.", logTag))
                    return false
                }
            } else {
                SOMAdapterLogger.log(String(format: "%@: Price point is no number.", logTag))
            }
        } else {
            SOMAdapterLogger.log(String(format: "%@: Minimum price point is no number.", logTag))
        }
        return true // Load Ad
    }
}

extension SOMAdapterAmazonDTB: DTBAdCallback {

    public func onFailure(_ error: DTBAdError) {
        var errorCode: GADErrorCode
        var message: String
        switch error.rawValue {
        case NETWORK_ERROR.rawValue:
            errorCode = GADErrorCode.networkError
            message = "Network error"
        case  NETWORK_TIMEOUT.rawValue:
            errorCode = GADErrorCode.timeout
            message = "Network timeout"
        case NO_FILL.rawValue:
            errorCode = GADErrorCode.noFill
            message = "No fill"
        case INTERNAL_ERROR.rawValue:
            errorCode = GADErrorCode.internalError
            message = "Internal error"
        case REQUEST_ERROR.rawValue:
            errorCode = GADErrorCode.invalidRequest
            message = "Request error"
        default:
            errorCode = GADErrorCode.invalidRequest
            message = "Invalid request"
        }

        SOMAdapterLogger.log(String(format: "%@: DTBAdLoader callback onFailure() triggered.", logTag))
        proceedWithOtherNetwork(errorCode, message: message)
    }

    public func onSuccess(_ adResponse: DTBAdResponse!) {
        SOMAdapterLogger.log(String(format: "%@: DTBAdLoader callback onSuccess() triggered.", logTag))
        // Get ad via DFP if pricepoint is ok
        let defaultPricePoints = adResponse.defaultPricePoints()
        if pricePointIsHigherThanMinimumPricePoint(minPricePointString: extractedParameters[KEY_MINPRICEPOINT],
                                                   pricePointString: defaultPricePoints) {
            SOMAdapterLogger.log(String(format: "%@: Price point check ok, request recommendation via DFP.", logTag))
            loadAdInDFP(targeting: adResponse.customTargetting())
        } else {
            SOMAdapterLogger.log(String(format: "%@: Amazon price point too low, continuing with next network.", logTag))
            proceedWithOtherNetwork(GADErrorCode.noFill, message: "Amazon price point too low")
        }
    }
}
