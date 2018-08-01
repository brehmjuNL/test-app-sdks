//
//  SOIAdapterYieldlab.swift
//  TestAppiOS
//
//  Created by brehmjuNL on 2018-06-18.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//
import Foundation
import GoogleMobileAds

@objc public class SOMAdapterYieldlab: SOMAdapter {

    let KEY_ADUNIT = "adUnit"
    let KEY_DELIVER = "deliver"
    let KEY_LATITUDE = "lat"
    let KEY_LONGITUDE = "long"
    
    override func processAdRequest(){
        let DFPAdRequest = buildDFPRequest(adUnit: extractedParameters[KEY_ADUNIT]!,
                                           customTargeting: getCustomTargeting())
        loadDFPAd(DFPAdRequest)
    }
    
    override func setLogTag(_ logSize: GADAdSize){
        logTag = String(format: "SOMAdapterYieldlab %ix%i", Int(size.size.width), Int(size.size.height))
    }
    
    override func setKeysToExtractFromParameterString(){
        requiredKeys = [KEY_ADUNIT]
        optionalKeys = [KEY_DELIVER]
    }
    
    func getCustomTargeting() -> [AnyHashable : Any]!{
        var targeting = [String:String]()
        if(extractedParameters[KEY_DELIVER] != nil){
            targeting[KEY_DELIVER] = extractedParameters[KEY_DELIVER]!
        }
        if(customEventRequest.userLatitude != 0.0 && customEventRequest.userLongitude != 0.0){
            targeting[KEY_LATITUDE] = String(format: "%@", customEventRequest.userLatitude)
            targeting[KEY_LONGITUDE] = String(format: "%@", customEventRequest.userLongitude)
        }
        return targeting
    }
}
