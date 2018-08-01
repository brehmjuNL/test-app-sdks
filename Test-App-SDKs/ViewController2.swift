//
//  ViewController2.swift
//  Test-App-SDKs
//
//  Created by Julian Brehm on 2018-08-01.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import UIKit
import GoogleMobileAds
import SOMYieldProbeSDK

class ViewController2: UIViewController {

    @IBOutlet weak var banner: BannerAd!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
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
}
