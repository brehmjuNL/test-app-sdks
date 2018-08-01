//
//  DisplayAds.swift
//  TestAppiOS
//
//  Created by Julian Brehm on 2018-06-13.
//  Copyright © 2018 Julian Brehm. All rights reserved.
//
import Foundation
import GoogleMobileAds

class BannerAd: GADBannerView, GADBannerViewDelegate {
    
    var response: Bool!
    var success: Bool!
    
    var bannerView: GADBannerView!
    var adNetwork: String!
    var timestamp: Double!
    
    let KEY_CUSTOMEVENTCLASSNAME = "GADMAdapterCustomEvents"
    
    var logTag: String!
    
    func create(controller: UIViewController,
                adUnitID: String,
                size: GADAdSize){
        logTag = String(format: "Banner Ad %ix%i", Int(size.size.width), Int(size.size.height))
        self.backgroundColor = UIColor.gray
        bannerView = DFPBannerView(adSize: size)
        bannerView.rootViewController = controller
        bannerView.delegate = self
        bannerView.adUnitID = adUnitID
        self.addSubview(bannerView)
        NSLog("%@: Initialized with AdUnit %@", logTag, adUnitID)
    }

    func getAdNetworkClassName() -> String {
        return adNetwork
    }
    
    func load(customTargeting: Dictionary<String, String>,
              npa: Bool,
              completion: @escaping (_ success: Bool, _ duration: Double) -> Void){
        NSLog("%@: Load ad with targeting=%@", logTag, customTargeting.debugDescription)
        response = false
        success = false
        adNetwork = ""
        bannerView.load(
            getDFPRequest(customTargeting: customTargeting,
                          additionalParameters: getAdditionalParameters(npa: npa))
        )
        timestamp = Date().timeIntervalSince1970
        // Wait until ad is loaded @todo: timeout
        DispatchQueue.global(qos: .userInitiated).async {
            while !self.response {}
            completion(self.success, Date().timeIntervalSince1970 - self.timestamp)
        }
    }
    
    func clear(){
        if(bannerView != nil){
            bannerView.removeFromSuperview()
        }
    }

    func getAdditionalParameters(npa: Bool) -> Dictionary<String, String>{
        //return ["npa": String(adConfig.getNPAValue())]
        return Dictionary<String, String>()
    }
    
    func getDFPRequest(customTargeting: Dictionary<String, String>,
                       additionalParameters: Dictionary<String, String>) -> DFPRequest {
        var request: DFPRequest!
        request = DFPRequest()
        request.customTargeting = customTargeting
        let extras = GADExtras()
        extras.additionalParameters = additionalParameters
        request.register(extras)
        for (key, value) in additionalParameters {
            NSLog("%@: Extra parameter: %@=%@", logTag, key, value)
        }
        return request
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerViewCustom: GADBannerView) {
        NSLog("%@: Callback adViewDidReceiveAd() triggered.", logTag)
        adNetwork = bannerViewCustom.adNetworkClassName
        response = true
        success = true
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        NSLog("%@: Callback adView:didFailToReceiveAdWithError() triggered with message: %@", logTag, error.localizedDescription)
        response = true
        success = false
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        NSLog("%@: Callback adViewWillPresentScreen() triggered.", logTag)
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        NSLog("%@: Callback adViewWillDismissScreen() triggered.", logTag)
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        NSLog("%@: Callback adViewDidDismissScreen() triggered.", logTag)
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        NSLog("%@: Callback adViewWillLeaveApplication() triggered.", logTag)
    }
}
