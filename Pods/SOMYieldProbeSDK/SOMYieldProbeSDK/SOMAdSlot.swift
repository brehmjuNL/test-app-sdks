//
//  SOMAdSlot.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-24.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import UIKit
import AdSupport

class SOMAdSlot {
    
    var id: Int!
    var type: String!
    var ttl: Int!
    var npa: Bool!
    var bid: SOMBid!
    var deviceType: String!
    var isRequesting: Bool!
    
    /**
     A new ad slot is initiated.
     - Parameter id, type, ttl, npa: See SOMYieldProbe class.
     - Parameter autoLoad: Defines weather a bid is requested directly after instantiation.
     */
    func initialize(id: Int,
                    type: String,
                    ttl: Int,
                    npa: Bool,
                    autoLoad: Bool){
        self.id = id
        self.type = type
        self.ttl = ttl
        self.npa = npa
        SOMYieldProbeLogger.log(String(format: "%@: Instanciated with values ttl=%d and npa=%d", SOMConfig.LOG_TAG_ADSLOT, ttl, npa))
        self.deviceType = UIDevice.current.userInterfaceIdiom == .pad ? SOMConfig.YP_DEVICE_KEY_TABLET : SOMConfig.YP_DEVICE_KEY_PHONE
        SOMYieldProbeLogger.log(String(format: "%@: Device type set to %@", SOMConfig.LOG_TAG_ADSLOT, self.deviceType))
        self.isRequesting = false
        if autoLoad {
            requestBid(force: true)
        }
    }
    
    func getBid() -> SOMBid {
        return self.bid
    }
    
    func setNpa(_ npa: Bool){
        self.npa = npa
    }
    
    /**
     - Returns: Targeting information used to load the YP bid as Ad via Google Ads SDK.
     */
    func getTargeting() -> [String: String]{
        if self.bid != nil {
            return self.bid.getTargeting()
        } else {
            return [String: String]()
        }
    }
    
    /**
     Request bid from YieldLab server for defined Ad slot.
     - Parameter force: Bid request is executed and bid overridden even if current bid is not expired. Otherwise this only happens if bid is expired.
     */
    func requestBid(force: Bool){ // Override current bit if it is expired or force mode is enabled
        if force == false
            && self.bid != nil
            && self.bid.isExpired() == false {
            SOMYieldProbeLogger.log(String(format: "%@: Request rejected, bid expired in %0.2f minutes.", SOMConfig.LOG_TAG_ADSLOT, bid.getRemainingLifetimeInMinutes()))
            return
        } else {
            SOMYieldProbeLogger.log(String(format: "%@: Request forced, get bid and override bid current one.", SOMConfig.LOG_TAG_ADSLOT))
        }
        SOMYieldProbeLogger.log(String(format: "%@: Request bid...", SOMConfig.LOG_TAG_ADSLOT))
        if SOMConnectivity.sharedService.isConnected() == false {
            SOMYieldProbeLogger.log(String(format: "%@: Device is not connected to the internet...", SOMConfig.LOG_TAG_ADSLOT))
            return
        }
        if self.isRequesting {
            SOMYieldProbeLogger.log(String(format: "%@: Bid is already being requested.", SOMConfig.LOG_TAG_ADSLOT))    
            return
        }
        self.isRequesting = true // Start new request phase
        let url = buildYieldprobeUrlString()
        
        getBidFromYieldLab(url) { (bidData: [String: Any]?) in
            if bidData == nil {
                SOMYieldProbeLogger.log(String(format: "%@: No bid received.", SOMConfig.LOG_TAG_ADSLOT))
                self.isRequesting = false
                return
            }
            guard let bidParameter = self.getBidParameter(bidData!) else {
                SOMYieldProbeLogger.log(String(format: "%@: Required keys missing.", SOMConfig.LOG_TAG_ADSLOT))
                self.isRequesting = false
                return
            }
            self.saveBid(bidParameter)
            self.isRequesting = false
        }
    }
    
    /**
     Get bid from YieldLab server for defined Ad slot.
     - Parameter url: YieldLab ad requets URL.
     - Returns: (after completion) Extracted bid parameters.
     */
    func getBidFromYieldLab(_ url: URL, completion: @escaping (_ data: [String: Any]?) -> Void){
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = SOMConfig.USE_COOKIES // Inportant! Enabled cookies affect the values returned from YieldLab!
        URLSession.shared.dataTask(with: request) { (data, res, err) in
            guard let data = data else {
                SOMYieldProbeLogger.log(String(format: "%@: No data received from server with message: %@", SOMConfig.LOG_TAG_ADSLOT, err.debugDescription))
                return
            }
            guard let bidData = self.parseJsonGetDictionary(data) else {
                SOMYieldProbeLogger.log(String(format: "%@: Json could not be parsed.", SOMConfig.LOG_TAG_ADSLOT))
                return
            }
            completion(self.extractBidInformation(bidData))
            return
        }.resume()
    }
    
    /**
     - Parameter data: Json data received from a URLSession.shared.dataTask.
     - Returns: Dictionary containing bid information.
     */
    func parseJsonGetDictionary(_ data: Data) -> [AnyObject]?{
        guard let string = String(bytes: data, encoding: .utf8) else {
            SOMYieldProbeLogger.log(String(format: "%@: Not able to create Json string from returned data.", SOMConfig.LOG_TAG_ADSLOT))
            return nil
        }
        SOMYieldProbeLogger.log(String(format: "%@: Json string from YieldLab server: %@", SOMConfig.LOG_TAG_ADSLOT, string))
        guard let jsonObject = string.data(using: String.Encoding.utf8, allowLossyConversion: false) else {
            SOMYieldProbeLogger.log(String(format: "%@: String is not a valid utf8 sequence.", SOMConfig.LOG_TAG_ADSLOT))
            return nil
        }
        guard let dataDictionary = try? JSONSerialization.jsonObject(with: jsonObject, options: []) else {
            SOMYieldProbeLogger.log(String(format: "%@: Json could not be parsed.", SOMConfig.LOG_TAG_ADSLOT))
            return nil
        }
        if dataDictionary is [AnyObject] {
            return dataDictionary as? [AnyObject]
        } else {
            SOMYieldProbeLogger.log(String(format: "%@: Json is not in the expected format.", SOMConfig.LOG_TAG_YIELDPROBE))
            return nil
        }
    }
    
    /**
     - Parameter data: Parsed data from URLSession.shared.dataTask in the correct format.
     - Returns: Passed bid information in format Int(Key) -> Any(Value) as Dictionary.
     */
    func extractBidInformation(_ data: [AnyObject]) -> [String: Any]?{
        if data.count < 1 {
            SOMYieldProbeLogger.log(String(format: "%@: No data available in Json.", SOMConfig.LOG_TAG_ADSLOT))
            return nil
        }
        guard let bidData = data[0] as? [String: Any] else {
            SOMYieldProbeLogger.log(String(format: "%@: Json doesn't contain a dictionary.", SOMConfig.LOG_TAG_ADSLOT))
            return nil
        }
        return bidData
    }
    
    /**
     - Parameter data: Bid data received from extracted with extractBidInformation().
     - Returns: Dictionary containing required and optional parameters with normalized values (Any->String).
     */
    func getBidParameter(_ data: [String: Any]) -> [String: String]? {
        var requiredKeysAreNotAvailable = false // Use this to log each missing parameter in Json!
        var recommendation = [String: String]()
        for key in SOMConfig.requiredKeys { // Check required keys and add them to reccomendation
            if data[key] == nil {
                SOMYieldProbeLogger.log(String(format: "%@: Parameter >%@< missing in Json.", SOMConfig.LOG_TAG_ADSLOT, key))
                requiredKeysAreNotAvailable = true
            } else {
                recommendation[key] = String(describing: data[key]!)
            }
        }
        if requiredKeysAreNotAvailable {
            return nil
        }
        for key in SOMConfig.optionalKeys { // Add optional keys to recommendation
            if data[key] != nil {
                recommendation[key] = String(describing: data[key]!)
            }
        }
        return recommendation
    }

    /**
     - Parameter bidParameter: Required and optional parameters for bid in Dictionary.
     */
    func saveBid(_ bidParameter: [String: String]) {
        SOMYieldProbeLogger.log(String(format: "%@: Save bid...", SOMConfig.LOG_TAG_ADSLOT))
        if self.bid != nil
            && !self.bid.isExpired(){
            SOMYieldProbeLogger.log(String(format: "%@: Though bid is not expired, override it...", SOMConfig.LOG_TAG_ADSLOT))
        }
        self.bid = SOMBid()
        self.bid.initialize(
            slotId: self.self.id,
            slotType: self.self.type,
            ttl: self.self.ttl,
            bidParameter: bidParameter)
    }
    
    /**
     Builds a URL instance used to request a bid from YieldLab for a specific slot containing targeting parameter.
     - Returns: YieldLab URL for bid request.
     */
    func buildYieldprobeUrlString() -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "ad.yieldlab.net"
        components.path = String(format: "/yp/%d", self.id)
        var queryItems = [URLQueryItem]()
        if !self.npa { // Non-personalized Ads
            let lat = SOMGeolocation.sharedService.latitude
            let lon = SOMGeolocation.sharedService.longitude
            if lat != nil && lon != nil {
                queryItems.append(URLQueryItem(name: "lat", value: String(describing: lat!)))
                queryItems.append(URLQueryItem(name: "lat", value: String(describing: lon!)))
            }
            // Only pass if IDFA is enabled
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                queryItems.append(URLQueryItem(name: "yl_rtb_ifa", value: ASIdentifierManager.shared().advertisingIdentifier.uuidString))
            }
        }
        queryItems.append(URLQueryItem(name: "json", value: "true"))
        queryItems.append(URLQueryItem(name: "pvid", value: "true"))
        queryItems.append(URLQueryItem(name: "yl_rtb_connectiontype", value: String(describing: SOMConnectivity.sharedService.getConnectionType())))
        queryItems.append(URLQueryItem(name: "yl_rtb_devicetype", value: self.deviceType))
        let ts = String(describing: Int(NSDate().timeIntervalSince1970))
        queryItems.append(URLQueryItem(name: "ts", value: ts))
        components.queryItems = queryItems
        SOMYieldProbeLogger.log(String(format: "%@: Rewuest url: %@", SOMConfig.LOG_TAG_ADSLOT, components.url!.debugDescription))
        return components.url!
    }
}
