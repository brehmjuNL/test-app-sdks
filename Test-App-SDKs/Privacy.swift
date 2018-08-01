//
//  Privacy.swift
//  Test-App-SDKs
//
//  Created by Julian Brehm on 2018-08-01.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import UIKit
import SOMYieldProbeSDK

class Privacy: UIViewController {

    @IBOutlet weak var npaToggle: UISwitch!
    
    @IBAction func toggleTriggered(_ sender: Any) {
        let npa = !npaToggle.isOn
        setNPAValue(value: npa)
        SOMYieldProbe.setNpa(npa)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SOMYieldProbe.update()
        npaToggle.isOn = !getNPAValue()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setNPAValue(value: Bool){
        UserDefaults.standard.set(value, forKey: "NPA")
    }
    
    func getNPAValue() -> Bool{
        let NPAUserDefaults = UserDefaults.standard.string(forKey: "NPA")
        if NPAUserDefaults != nil {
            return NPAUserDefaults! == "1"
        }
        return false
    }
}
