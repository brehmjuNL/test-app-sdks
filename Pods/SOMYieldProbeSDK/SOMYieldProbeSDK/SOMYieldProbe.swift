//
//  SOMYieldProbe.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-24.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import Foundation

public class SOMYieldProbe {
    
    static var notInitialized = true
    static var slotDict = [Int: SOMAdSlot]()
    static var npa: Bool = false
    static var ttl: Int? = nil // Must be nil at beginning
    
    /**
     Initialize the YieldProbe SDK with Json config.
     - Parameter config: Config as Json string containing id and type of available slots
     - Parameter npa: Non-personalized Ads enabled or disabled (if not passed default value is used)
     */
    public static func initialize(_ config: String){
        initialize(config, npa: SOMConfig.NPA_DEFAULT)
    }
    public static func initialize(_ config: String, npa: Bool){
        guard let configData = parseJsonGetDictionary(config) else {
            SOMYieldProbeLogger.log(String(format: "%@: YieldProbe SDK could not be initialized.", SOMConfig.LOG_TAG_YIELDPROBE))
            return
        }
        initialize(extractSlots(configData), npa: npa)
    }
    
    /**
     Initialize the YieldProbe SDK with slot Dictionary.
     - Parameter slots: Dictionary containing is as Integer and type as string of available slots
     - Parameter npa: Non-personalized Ads enabled or disabled (if not passed default value is used)
     */
    public static func initialize(_ slots: [Int: String]){
        initialize(slots, npa: SOMConfig.NPA_DEFAULT)
    }
    public static func initialize(_ slots: [Int: String], npa: Bool){
        if self.notInitialized {
            self.npa = npa
            let ttl = (self.ttl != nil) ? self.ttl : SOMConfig.DEFAULT_TTL
            SOMYieldProbeLogger.log(String(format: "%@: Initialize YieldProbe SDK... create shared preferences with values npa=%d and slots=%@", SOMConfig.LOG_TAG_YIELDPROBE, npa, slots.debugDescription))
            if slots.count < 1 {
                SOMYieldProbeLogger.log(String(format: "%@: No ad slots defined, please check SDK integration.", SOMConfig.LOG_TAG_YIELDPROBE))
            }
            for (id, type) in slots {
                let slotInstance = SOMAdSlot()
                slotInstance.initialize(id: id,
                                        type: type,
                                        ttl: ttl!,
                                        npa: self.npa,
                                        autoLoad: SOMConfig.AUTOLOAD_AFTER_INIT)
                self.slotDict[id] = slotInstance
            }
            self.notInitialized = false
        } else {
            SOMYieldProbeLogger.log(String(format: "%@: YieldProbe SDK is already initialized, ignore initialization and update.", SOMConfig.LOG_TAG_YIELDPROBE))
            if SOMConfig.UPDATE_IF_ALREADY_INIT {
                update()
            }
        }
    }
    
    public static func setTtl(_ ttl: Int){
        if !isInitialized() { return }
        self.ttl = ttl
    }
    
    public static func setNpa(_ npa: Bool){
        if !isInitialized() { return }
        self.npa = npa
        SOMYieldProbeLogger.log(String(format: "%@: NPA %@.", SOMConfig.LOG_TAG_YIELDPROBE, npa ? "enabled" : "disabled"))
    }
    
    /**
     Request new bids for each slot if current bid is not expired yet or request is forced.
     */
    public static func update(){
        if !isInitialized() { return }
        for (id, slotInstance) in self.slotDict {
            SOMYieldProbeLogger.log(String(format: "%@: Request new bid for slot %d...", SOMConfig.LOG_TAG_YIELDPROBE, id))
            slotInstance.setNpa(self.npa) // Could be changed by now
            slotInstance.requestBid(force: SOMConfig.OVERRIDE_BIDS_AT_UPDATE)
        }
    }
    
    /**
     - Parameter slotId: Identifier describing an unique YP slot.
     - Returns: Custom targeting for Ad requests via Google Ads SDK targeting the YP line item. Is empty if no bid is available.
     */
    public static func getTargeting(slotId: Int) -> [String: String] {
        if !isInitialized() { return [String: String]() }
        if let adSlot = self.slotDict[slotId] {
            SOMYieldProbeLogger.log(String(format: "%@: Return targeting for slot %d...", SOMConfig.LOG_TAG_YIELDPROBE, slotId))
            let targeting = adSlot.getTargeting()
            if SOMConfig.REQUEST_BID_AFTER_GET_TARGETING {
                SOMYieldProbeLogger.log(String(format: "%@: Request new bid for slot %d...", SOMConfig.LOG_TAG_YIELDPROBE, slotId))
                adSlot.requestBid(force: true)
            }
            return targeting
        } else {
            SOMYieldProbeLogger.log(String(format: "%@: No slot defined for id=%d", SOMConfig.LOG_TAG_YIELDPROBE, slotId))
        }
        return [String: String]()
    }
    
    static func isInitialized() -> Bool{
        if notInitialized {
            SOMYieldProbeLogger.log(String(format: "%@: YieldProbe SDK not initialized, please check SDK integration.", SOMConfig.LOG_TAG_YIELDPROBE))
            return false
        } else {
            return true
        }
    }
    
    /**
     - Parameter string: String containing slot information in Json format.
     - Returns: Dictionary containing slot information.
     */
    static func parseJsonGetDictionary(_ string: String) -> [String : [String : Any]]? {
        guard let jsonObject = string.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            SOMYieldProbeLogger.log(String(format: "%@: String is not a valid utf8 sequence.", SOMConfig.LOG_TAG_YIELDPROBE))
            return nil
        }
        guard let slotsData = try? JSONSerialization.jsonObject(with: jsonObject, options: []) else {
            SOMYieldProbeLogger.log(String(format: "%@: Json could not be parsed.", SOMConfig.LOG_TAG_YIELDPROBE))
            return nil
        }
        if slotsData is [String : [String : Any]] {
            return slotsData as? [String : [String : Any]]
        } else {
            SOMYieldProbeLogger.log(String(format: "%@: Json is not in the expected format.", SOMConfig.LOG_TAG_YIELDPROBE))
            return nil
        }
    }
    
    /**
     - Parameter data: Parsed data from config Json in the correct format.
     - Returns: Passed slots in format Int(id) -> String(type) as Dictionary.
     */
    static func extractSlots(_ data: [String : [String : Any]]) -> [Int: String]{
        var out = [Int : String]()
        for (_, info) in data {
            if let slotIdString = info[SOMConfig.KEY_JSON_CONFIG_ID] as? Int {
                if let slotTypeString = info[SOMConfig.KEY_JSON_CONFIG_SLOT] as? String {
                    out[slotIdString] = slotTypeString
                }
            }
        }
        return out
    }
    
    // --- DEBUG
    
    public static func enableDebug(){
        SOMYieldProbeLogger.enableLogging()
    }
    
    public static func getDetailedDescription(adSlotId: Int) -> String{
        let adSlot = self.slotDict[adSlotId]
        if adSlot != nil {
            let bid = adSlot?.getBid()
            if bid != nil {
                return bid!.toString()
            }
            return "No bid found."
        }
        return "Ad slot not found."
    }
}
