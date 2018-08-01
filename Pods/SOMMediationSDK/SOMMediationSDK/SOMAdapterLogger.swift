//
//  SEAdapterUtils.swift
//  TestAppiOS
//
//  Created by brehmjuNL on 2018-06-15.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//
import Foundation
import os.log

public class SOMAdapterLogger {
    
    static var logLevel = 1 // Enable logging
    
    static func setLogLevel(_ level: Int) {
        logLevel = level
    }
    
    static func isLogEnabled() -> Bool{
        return logLevel > 0
    }
    
    static func log(_ str: String){
        if (logLevel > 0) {
            DispatchQueue.main.async{
                //os_log(str, log: OSLog.default)
                NSLog("%@", str)
            }
        }
    }
}
