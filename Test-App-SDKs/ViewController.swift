//
//  ViewController.swift
//  Test-App-SDKs
//
//  Created by Julian Brehm on 2018-08-01.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import UIKit
import GoogleMobileAds
import SOMYieldProbeSDK

class ViewController: UIViewController {

    @IBOutlet weak var banner: BannerAd!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let npa = getNPAValue()
        
        let config = "{\"banner\":{\"id\":6118022,\"slot\":\"mb1\"},\"rectangle\":{\"id\":6118024,\"slot\":\"rt1\"},\"interstitial\":{\"id\":6118023,\"slot\":\"ml1\"}}" // Extracted from ad config in live env
        SOMYieldProbe.enableDebug()
        SOMYieldProbe.initialize(config, npa: npa)
        
        self.banner.create(controller: self,
                          adUnitID: "/5731/showroom/test",
                          size: kGADAdSizeBanner)

        self.loader.isHidden = false
        self.loader.startAnimating()
        self.banner.load(customTargeting: getCustomTargetingWithYP(slotId: 6118022),
                        npa: false){ // force personalized ads
                            (success: Bool, duration: Double) in
                            DispatchQueue.main.async{
                                self.loader.isHidden = true
                                self.loader.stopAnimating()
                            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCustomTargetingWithYP(slotId: Int) -> [String: String] {
        var targeting = SOMYieldProbe.getTargeting(slotId: slotId)
        targeting["showroom"] = "yp_inapp"
        return targeting
    }
    
    func getNPAValue() -> Bool{
        let NPAUserDefaults = UserDefaults.standard.string(forKey: "NPA")
        if NPAUserDefaults != nil {
            return NPAUserDefaults! == "1"
        }
        return false
    }
}

