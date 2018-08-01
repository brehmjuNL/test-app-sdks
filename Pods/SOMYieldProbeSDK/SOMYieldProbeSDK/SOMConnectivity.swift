//
//  SOMConnectivity.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-24.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import Foundation
import CoreTelephony

class SOMConnectivity {
    
    static let sharedService = SOMConnectivity() // Singleton
    
    /**
     Object is initialized when shared service is first called
     */
    init(){
        do {
            Network.reachability = try SOMReachability()
        } catch {
            SOMYieldProbeLogger.log(String(format: "%@: Unknown error while requesting connection state.", SOMConfig.LOG_TAG_CON))
        }
    }
    
    func isConnected() -> Bool {
        if noNetworkIsConnected() {
            return false // Internet connection unavailable, reachability status not reachable
        } else {
            return true // Internet connection available, reachability status .wifi or .wwan
        }
    }
    
    func noNetworkIsConnected() -> Bool {
        guard let status = Network.reachability?.status else {
            return false
        }
        return status == .unreachable
            || (status == .unknown
                && !SOMConfig.ASSUME_CONNECTION_IF_UNKNOWN)
    }

    /**
     - Returns: Mapping form general network state to Integer value
     */
    func getConnectionType() -> Int {
        guard let status = Network.reachability?.status else {
            return SOMConfig.YP_NETWORK_STATE_UNKNOWN
        }
        switch status {
        case .wifi:
            SOMYieldProbeLogger.log(String(format: "%@: Reachable via WIFI.", SOMConfig.LOG_TAG_CON))
            return SOMConfig.YP_NETWORK_STATE_WIFI
        case .wwan:
            SOMYieldProbeLogger.log(String(format: "%@: Reachable via WWAN.", SOMConfig.LOG_TAG_CON))
            return getCellularConnectionType()
        case .unreachable:
            SOMYieldProbeLogger.log(String(format: "%@: Not reachable.", SOMConfig.LOG_TAG_CON))
            return SOMConfig.YP_NETWORK_STATE_UNKNOWN
        case .unknown:
            SOMYieldProbeLogger.log(String(format: "%@: Unknown network state.", SOMConfig.LOG_TAG_CON))
            return SOMConfig.YP_NETWORK_STATE_UNKNOWN
        }
    }
    
    /**
     - Returns: Mapping form WWAN network state to Integer representation
     */
    func getCellularConnectionType() -> Int{
        let telephonyInfo = CTTelephonyNetworkInfo()
        let currentRadio = telephonyInfo.currentRadioAccessTechnology
        switch currentRadio {
        case CTRadioAccessTechnologyGPRS:
            return SOMConfig.YP_NETWORK_STATE_2G
        case CTRadioAccessTechnologyCDMA1x:
            return SOMConfig.YP_NETWORK_STATE_2G
        case CTRadioAccessTechnologyEdge:
            return SOMConfig.YP_NETWORK_STATE_2_5G
        case CTRadioAccessTechnologyWCDMA:
            return SOMConfig.YP_NETWORK_STATE_3G
        case CTRadioAccessTechnologyCDMAEVDORev0:
            return SOMConfig.YP_NETWORK_STATE_3G
        case CTRadioAccessTechnologyCDMAEVDORevA:
            return SOMConfig.YP_NETWORK_STATE_3G
        case CTRadioAccessTechnologyCDMAEVDORevB:
            return SOMConfig.YP_NETWORK_STATE_3G
        case CTRadioAccessTechnologyeHRPD:
            return SOMConfig.YP_NETWORK_STATE_3G
        case CTRadioAccessTechnologyHSDPA:
            return SOMConfig.YP_NETWORK_STATE_3_5G
        case CTRadioAccessTechnologyHSUPA:
            return SOMConfig.YP_NETWORK_STATE_3_5G
        case CTRadioAccessTechnologyLTE:
            return SOMConfig.YP_NETWORK_STATE_4G
        default:
            return SOMConfig.YP_NETWORK_STATE_UNKNOWN_WWAN
        }
    }
}
