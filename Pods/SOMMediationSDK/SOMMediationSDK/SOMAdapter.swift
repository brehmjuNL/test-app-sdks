//
//  SOMAdapter.swift
//  SOMMediationFramework
//
//  Created by Julian Brehm on 2018-07-19.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import UIKit
import GoogleMobileAds

let customEventErrorDomain: String = "com.google.CustomEvent"

public class SOMAdapter: UIViewController, GADCustomEventBanner {
    
    let KEY_DEBUG = "debug"
    let KEY_TESTING = "testing"
    let VALUE_FALLBACKNAME = "fallback"
    let VALUE_FALLBACKINFO = "true"
    let KEY_TARGETING_GMA = "gma"
    let VALUE_TARGETING_GMA = "1"
    
    // Disable logging and testing if not defined in Ad request
    var debug = 0
    var testing = false
    
    var logTag = ""
    var extractedParameters =  Dictionary<String, String>()
    var size: GADAdSize!
    var customEventRequest: GADCustomEventRequest!
    var dimension: GADAdSize!
    
    var requiredKeys: [String]!
    var optionalKeys: [String]!
    
    var DFPAdView: DFPBannerView!
    
    public var delegate: GADCustomEventBannerDelegate?
    
    public func requestAd(_ adSize: GADAdSize,
                          parameter serverParameter: String?,
                          label serverLabel: String?,
                          request: GADCustomEventRequest) {
        
        size = adSize // Make accessible globally
        
        if mapSizeToDimension() == false { // Returnes false if Ad size in Ad request is unknown
            SOMAdapterLogger.log(String(format: "%@: Unknown Ad size in initial Ad request (%@)", logTag, size.size as CVarArg))
            proceedWithOtherNetwork(GADErrorCode.invalidRequest, message: "Unknown Ad size")
        } else {
            setLogTag(size)
            SOMAdapterLogger.log(String(format: "%@: Custom event triggerd by Google Ads SDK, label=%@", logTag, serverLabel!))
            
            customEventRequest = request // Custom targeting of initial Ad request accessible in this object
    
            setKeysToExtractFromParameterString()
            extractParams(serverParameter)
            
            if requiredParametersMissing(keys: requiredKeys) {
                SOMAdapterLogger.log(String(format: "%@: Required parameters missing in parameter string.", logTag))
                logParameters(keys: requiredKeys)
                proceedWithOtherNetwork(GADErrorCode.invalidRequest, message: "Required values missing")
            } else {
                SOMAdapterLogger.setLogLevel(debug)
                SOMAdapterLogger.log(String(format: "%@: Logging enabled on level %i and testing %@.", logTag, debug, testing ? "enabled" : "disabled"))
                logParameters(keys: requiredKeys + optionalKeys)
                processAdRequest()
            }
        }
    }
    
    /*
     * Methods must be overridden by custom adapter classes
     */
        func setLogTag(_ logSize: GADAdSize){ // Override!
            logTag = String(format: "Unknown adapter %ix%i", Int(size.size.width), Int(size.size.height))
        }
        func setKeysToExtractFromParameterString(){ // Override!
            requiredKeys = []
            optionalKeys = []
            SOMAdapterLogger.log(String(format: "%@: No keys to extract from parameter string.", logTag))
        }
        func processAdRequest(){ // Override!
            SOMAdapterLogger.log(String(format: "%@: No network defined.", logTag))
        }
    
    func consentStringIsZero() -> Bool { // If the IAB consent string is zero the user has opted out of personalized ads
        let consentString = UserDefaults.standard.string(forKey: "IABConsent_ConsentString")
        if(consentString != nil){
            if consentString == "0" {
                return true
            }
        }
        return false
    }
    
    func buildDFPRequest(adUnit: String,
                         customTargeting: [AnyHashable : Any]!) -> DFPRequest {
        DFPAdView = DFPBannerView(adSize: dimension)
        DFPAdView?.delegate = self
        DFPAdView?.appEventDelegate = self
        DFPAdView?.enableManualImpressions = true
        DFPAdView?.adUnitID = adUnit
        DFPAdView?.rootViewController = self
        let DFPAdRequest = DFPRequest()
        
        // Add key-values
        var customTargetingModified = customTargeting
        customTargetingModified![KEY_TARGETING_GMA] = VALUE_TARGETING_GMA
        
        DFPAdRequest.customTargeting = customTargetingModified
        for (key, value) in customTargeting {
            SOMAdapterLogger.log(String(format:"%@: Add custom targeting key-value %@=%@", logTag, key as CVarArg, value as! CVarArg))
        }
        
        // Add location of initial Ad requet
        DFPAdRequest.setLocationWithLatitude(customEventRequest.userLatitude,
                                             longitude: customEventRequest.userLongitude,
                                             accuracy: customEventRequest.userLocationAccuracyInMeters) // Set location data in ad request and also pass it as custom targeting data
        return DFPAdRequest
    }
    
    func loadDFPAd(_ requestDFPAd: DFPRequest){
        SOMAdapterLogger.log(String(format: "%@: Load DFP Ad...", logTag))
        DFPAdView?.load(requestDFPAd)
    }
    
    func mapSizeToDimension() -> Bool { // The Ad size must be known and mapped to a standard banner size
        var rect = CGRect()
        rect.size = CGSizeFromGADAdSize(size)
        
        let perfBannerPhone = CGSize(width: 320.0, height: 60.0);
        let perfBannerTablet = CGSize(width: 728.0, height: 100.0);
        let perfRectangle = CGSize(width: 300.0, height: 260.0);
        
        switch rect.size {
        case CGSizeFromGADAdSize(kGADAdSizeBanner):
            dimension = kGADAdSizeBanner
        case CGSizeFromGADAdSize(kGADAdSizeLeaderboard):
            dimension = kGADAdSizeLeaderboard
        case CGSizeFromGADAdSize(kGADAdSizeMediumRectangle):
            dimension = kGADAdSizeMediumRectangle
        case perfBannerPhone:
            dimension = kGADAdSizeBanner
        case perfBannerTablet:
            dimension = kGADAdSizeLeaderboard
        case perfRectangle:
            dimension = kGADAdSizeMediumRectangle
        default:
            return false // Error, Ad size unknown
        }
        return true // Ad size known
    }
    
    func proceedWithOtherNetwork(_ errorCode: GADErrorCode, message: String){ // Skip Ad network
        let userInfo = ["details": message]
        let appKeyError = NSError(domain: customEventErrorDomain, code: errorCode.rawValue, userInfo: userInfo)
        SOMAdapterLogger.log(String(format: "%@: Proceed with other network, reason: %@", logTag, message))
        delegate?.customEventBanner(self, didFailAd: appKeyError)
        return
    }
    
    func requiredParametersMissing(keys: [String]) -> Bool {
        var keyMissing = false
        for key in keys {
            if extractedParameters[key] == nil {
                keyMissing = true
            }
        }
        return keyMissing
    }
    
    func logParameters(keys: [String]){
        for key in keys {
            if(extractedParameters[key] == nil) {
                SOMAdapterLogger.log(String(format: "%@: %@ not set", logTag, key))
            } else {
                SOMAdapterLogger.log(String(format: "%@: %@=%@", logTag, key, extractedParameters[key]!))
            }
        }
    }
    
    func extractParams(_ queryString: String?){
        if let kvStrings = queryString?.components(separatedBy: "&"){
            if kvStrings.count > 0 {
                for kvStr in kvStrings {
                    let kv = kvStr.components(separatedBy: "=")
                    if kv[0].lowercased() == KEY_DEBUG.lowercased() {
                        debug = Int(kv[1])! // Cast to Int
                    } else if kv[0].lowercased() == KEY_TESTING.lowercased() {
                        testing = (Int(kv[1])! < 1) ? false : true // Cast to Bool
                    } else {
                        if requiredKeys.count > 0 {
                            for key1 in requiredKeys {
                                if kv[0].lowercased() == key1.lowercased() {
                                    if !kv[1].elementsEqual("") {
                                        extractedParameters[key1] = kv[1]
                                    }
                                }
                            }
                        }
                        if optionalKeys.count > 0 {
                            for key2 in optionalKeys {
                                if kv[0].lowercased() == key2.lowercased() {
                                    if !kv[1].elementsEqual("") {
                                        extractedParameters[key2] = kv[1]
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension SOMAdapter: GADBannerViewDelegate, GADAppEventDelegate {
    
    // Tells the delegate that an ad request successfully received an ad. The delegate may want to add
    // the banner view to the view hierarchy if it hasn't been added yet.
    public func adViewDidReceiveAd(_ bannerView: GADBannerView){
        SOMAdapterLogger.log(String(format: "%@: Callback adViewDidReceiveAd() triggered.", logTag))
        delegate?.customEventBanner(self, didReceiveAd: bannerView)
    }
    
    // Tells the delegate that an ad request failed. The failure is normally due to network
    // connectivity or ad availablility (i.e., no fill).
    public func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError){
        SOMAdapterLogger.log(String(format: "%@: Callback adView() triggered with message: %@", logTag, error.localizedDescription))
        delegate?.customEventBanner(self, didFailAd: error)
    }
    
    // Tells the delegate that a full screen view will be presented in response to the user clicking on
    // an ad. The delegate may want to pause animations and time sensitive interactions.
    public func adViewWillPresentScreen(_ bannerView: GADBannerView){
        SOMAdapterLogger.log(String(format: "%@: Callback adViewWillPresentScreen() triggered.", logTag))
    }
    
    // Tells the delegate that the full screen view will be dismissed.
    public func adViewWillDismissScreen(_ bannerView: GADBannerView){
        SOMAdapterLogger.log(String(format: "%@: Callback adViewWillDismissScreen() triggered.", logTag))
    }
    
    // Tells the delegate that the full screen view has been dismissed. The delegate should restart
    // anything paused while handling adViewWillPresentScreen:.
    public func adViewDidDismissScreen(_ bannerView: GADBannerView){
        SOMAdapterLogger.log(String(format: "%@: Callback adViewDidDismissScreen() triggered.", logTag))
    }
    
    // Tells the delegate that the user click will open another app, backgrounding the current
    // application. The standard UIApplicationDelegate methods, like applicationDidEnterBackground:,
    // are called immediately before this method is called.
    public func adViewWillLeaveApplication(_ bannerView: GADBannerView){
        SOMAdapterLogger.log(String(format: "%@: Callback adViewWillLeaveApplication() triggered.", logTag))
        delegate?.customEventBannerWasClicked(self)
        delegate?.customEventBannerWillLeaveApplication(self)
    }
    
    // Called when a yieldlab ad view receives a fallback event.
    public func adView(_ bannerView: GADBannerView, didReceiveAppEvent name: String, withInfo info: String?){
        SOMAdapterLogger.log(String(format: "%@: Callback adView() triggered with name=%@ and info=%@", logTag, name, info!))
        if name.elementsEqual(VALUE_FALLBACKNAME) && (info?.elementsEqual(VALUE_FALLBACKINFO))! {
            SOMAdapterLogger.log(String(format: "%@: Call didFailAd() because response is a fallback.", logTag, name))
            proceedWithOtherNetwork(GADErrorCode.noFill, message: "Fallback ad received")
        }
    }
}
