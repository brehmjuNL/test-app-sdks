//
//  SOIAdapterSmaato.swift
//  TestAppiOS
//
//  Created by brehmjuNL on 2018-06-14.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//
import Foundation
import GoogleMobileAds
import iSoma

@objc public class SOMAdapterSmaato: SOMAdapter {
    
    public var SOMABannerAd: SOMAAdView?
    
    let KEY_PUBLISHERID = "publisher"
    let KEY_ADSPACEID = "adSpace"
    
    override func processAdRequest(){
        buildSOMARequest()
        loadSOMAAd()
    }
    
    override func setLogTag(_ logSize: GADAdSize){
        logTag = String(format: "SOMAdapterSmaato %ix%i", Int(size.size.width), Int(size.size.height))
    }
    
    override func setKeysToExtractFromParameterString(){
        requiredKeys = [KEY_PUBLISHERID, KEY_ADSPACEID]
        optionalKeys = []
    }
    
    func buildSOMARequest(){
        var rect = CGRect()
        rect.size = CGSizeFromGADAdSize(size)
        SOMABannerAd = SOMAAdView()
        SOMABannerAd?.adSettings.publisherId = Int(extractedParameters[KEY_PUBLISHERID]!)!
        SOMABannerAd?.adSettings.adSpaceId = Int(extractedParameters[KEY_ADSPACEID]!)!
        SOMABannerAd?.adSettings.type = SOMAAdType.all
        SOMABannerAd?.adSettings.httpsOnly = true
        SOMABannerAd?.adSettings.dimension = mapDimensionDFPToSOMA()
        SOMABannerAd?.adSettings.isAutoReloadEnabled = false
        SOMABannerAd?.delegate = self
        SOMABannerAd?.frame = rect
        self.view = SOMABannerAd // Add banner to view hierarchy
    }
    
    func loadSOMAAd(){
        SOMAdapterLogger.log(String(format: "%@: Load SOMA Ad...", logTag))
        SOMABannerAd?.load()
    }
    
    func mapDimensionDFPToSOMA() -> SOMAAdDimension { // Map DFP Ad size to SOMA Ad size
        switch dimension.size {
            case kGADAdSizeBanner.size:
                return SOMAAdDimension.default
            case kGADAdSizeLeaderboard.size:
                return SOMAAdDimension.leader
            case kGADAdSizeMediumRectangle.size:
                return SOMAAdDimension.medRect
            default:
                return SOMAAdDimension.default
        }
    }
}

extension SOMAdapterSmaato: SOMAAdViewDelegate {
    /*
     somaRootViewController:
     @brief Return a UIViewController instance that can present another view controller modally.
     @warning  Not implementing this method returning appropriate view controller might result in unusual behavior
     @attention If it is not implemented or return nil, banner will try to find a usable UIViewController but which may not work always depending the view hierarchy.
     */
    public func somaRootViewController() -> UIViewController {
        SOMAdapterLogger.log(String(format: "%@: Callback somaRootViewController() triggered.", logTag))
        return self
    }
    
    public func somaAdViewWillLoadAd(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewWillLoadAd() triggered.", logTag))
    }
    
    public func somaAdViewDidLoadAd(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewDidLoadAd() triggered.", logTag))
        delegate?.customEventBanner(self, didReceiveAd: adview)
    }
    
    public func somaAdView(_ banner: SOMAAdView, didFailToReceiveAdWithError error: Error){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdView() triggered with message: %@", logTag, error.localizedDescription))
        delegate?.customEventBanner(self, didFailAd: error)
    }
    
    public func somaAdViewDidClick(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewDidClick() triggered.", logTag))
    }
    
    public func somaAdViewWillEnterFullscreen(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewWillEnterFullscreen() triggered.", logTag))
    }
    
    public func somaAdViewDidEnterFullscreen(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewDidEnterFullscreen() triggered.", logTag))
        delegate?.customEventBannerWasClicked(self)
        delegate?.customEventBannerWillLeaveApplication(self)
    }
    
    public func somaAdViewWillExitFullscreen(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewWillExitFullscreen() triggered.", logTag))
    }
    
    public func somaAdViewDidExitFullscreen(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewDidExitFullscreen() triggered.", logTag))
        delegate?.customEventBanner(self, didReceiveAd: adview)
    }
    
    public func somaAdViewApplicationWillGoBackground(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewApplicationWillGoBackground() triggered.", logTag))
    }
    
    public func somaAdViewApplicationDidBecomeActive(_ adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewApplicationDidBecomeActive() triggered.", logTag))
    }
    
    public func somaAdViewWillLeaveApplication(fromAd adview: SOMAAdView){
        SOMAdapterLogger.log(String(format: "%@: Callback somaAdViewWillLeaveApplication() triggered.", logTag))
    }
}
