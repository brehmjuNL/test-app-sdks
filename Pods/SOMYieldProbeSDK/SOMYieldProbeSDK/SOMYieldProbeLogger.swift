//
//  SOMYieldProbeLogger.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-24.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import Foundation

public class SOMYieldProbeLogger {
    
    static var loggingEnabled = false
    
    static func enableLogging(){
        self.loggingEnabled = true
    }
    
    static func log(_ str: String){
        if self.loggingEnabled {
            DispatchQueue.main.async{
                NSLog("%@", str)
            }
        }
    }
}
