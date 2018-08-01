//
//  SOMReachability.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-30.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import Foundation
import SystemConfiguration

struct Network {
    static var reachability: SOMReachability?
    enum Status: String, CustomStringConvertible {
        case unreachable, wifi, wwan, unknown
        var description: String { return rawValue }
    }
    enum Error: Swift.Error {
        case failedToInitializeWith(sockaddr_in)
    }
}

class SOMReachability {
    var reachability: SCNetworkReachability?
    
    init?() throws {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        guard let reachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }}) else {
                throw Network.Error.failedToInitializeWith(zeroAddress)
        }
        self.reachability = reachability
    }
    
    
    var status: Network.Status {
        if flags == nil {
            return .unknown
        }
        return !isConnectedToNetwork() ? .unreachable : (isReachableViaWiFi() ? .wifi : .wwan)
    }

    var flags: SCNetworkReachabilityFlags? {
        guard let reachability = reachability else {
            return nil
        }
        var flags = SCNetworkReachabilityFlags()
        return withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachability, UnsafeMutablePointer($0))
            } ? flags : nil
    }
    
    func isConnectedToNetwork() -> Bool {
        return isReachable() && !isConnectionRequiredAndTransientConnection()
    }
    
    func isReachableViaWiFi() -> Bool {
        return isReachable() && !isWWAN()
    }
    
    func isReachable() -> Bool {
        return flags!.contains(.reachable) == true
    }
    
    func isWWAN() -> Bool {
        return flags!.contains(.isWWAN) == true
    }
    
    func isConnectionRequiredAndTransientConnection() -> Bool {
        return (flags!.intersection([.connectionRequired, .transientConnection]) == [.connectionRequired, .transientConnection]) == true
    }
}
