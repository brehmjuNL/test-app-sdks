//
//  SOMBid.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-24.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import Foundation

class SOMBid {
    
    var creationTime: NSDate!
    var slotId: Int!
    var slotType: String!
    var ttl: Int!
    var bidParameter: [String: String]!
    
    /**
     A new ad bid is initiated.
     - Parameter slotId, slotType, ttl: See SOMYieldProbe class.
     - Parameter bidParameter: Required and optional parameter used to generate custom targeting.
     */
    func initialize (slotId: Int,
                     slotType: String,
                     ttl: Int,
                     bidParameter: [String: String]){
        self.creationTime = NSDate()
        self.slotId = slotId
        self.slotType = slotType
        self.ttl = ttl
        self.bidParameter = bidParameter
        SOMYieldProbeLogger.log(String(format: "%@: Bid created at %@", SOMConfig.LOG_TAG_BID, self.creationTime.debugDescription))
        for (key, value) in bidParameter {
            SOMYieldProbeLogger.log(String(format: "%@: Parameter: %@=%@", SOMConfig.LOG_TAG_BID, key, value))
        }
    }
    
    /**
     - Returns: A bid is expired if time since creation is larger than ttl.
     */
    func isExpired() -> Bool {
        // 1 second -> 1000 milliseconds
        // ttl in milliseconds
        // timeIntervalSinceNow in seconds
        let interval = self.creationTime.timeIntervalSinceNow
        if interval < 0 {
            if (fabs(interval) * 1000) < Double(self.ttl) {
                return false
            } else {
                return true
            }
        } else {
            return true // This should never happen. Consider this case as a failure and return true to indicate that this bid object should not be used.
        }
    }
    
    func getRemainingLifetimeInMinutes() -> Double {
        // 1 minute -> 60000 milliseconds
        let remainingLifetime = (Double(self.ttl) - fabs(self.creationTime.timeIntervalSinceNow * 1000)) / 60000
        return remainingLifetime
    }
    
    /**
     - Returns: Puts each required parameter plus 'priority' into a Dictionary as key-value.
     */
    func getTargeting() -> [String: String] {
        for key in SOMConfig.requiredKeys {
            if self.bidParameter[key] == nil {
                SOMYieldProbeLogger.log(String(format: "%@: Parameter missing for valid targeting.", SOMConfig.LOG_TAG_BID))
                return [String: String]()
            }
        }
        let priority = String(format:"%@,%@p%@", self.slotType, self.slotType, self.bidParameter[SOMConfig.KEY_YL_PRIO]!)
        return [SOMConfig.KEY_DFP_AID: String(describing: self.slotId!),
                SOMConfig.KEY_DFP_PID: self.bidParameter[SOMConfig.KEY_YL_PID]!,
                SOMConfig.KEY_DFP_PVID: self.bidParameter[SOMConfig.KEY_YL_PVID]!,
                SOMConfig.KEY_DFP_YL: priority]
    }
    
    /**
     - Returns: Puts each required and optional parameter plus additional information into a Dictionary as key-value.
     */
    func toString() -> String {
        var out = "{"
        out = String(format: "%@id:%@", out, String(describing: self.slotId!))
        out = String(format: "%@,type:%@", out, String(describing: self.slotType!))
        out = String(format: "%@,created:%@", out, self.creationTime.description)
        out = String(format: "%@,livetime:%@", out, String(Int(fabs(self.creationTime.timeIntervalSinceNow) * 1000)))
        out = String(format: "%@,ttl:%@", out, String(describing: self.ttl!))
        for (key, value) in self.bidParameter {
            out = String(format: "%@,%@:%@", out, key, value)
        }
        return String(format: "%@\n}", out)
    }
}
