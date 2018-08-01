//
//  SOMConfig.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-24.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

class SOMConfig {
    static let KEY_YL_ID = "id"
    static let KEY_YL_ADVERTISER = "advertiser"
    static let KEY_YL_CURL = "curl"
    static let KEY_YL_FORMAT = "format"
    static let KEY_YL_PID = "pid"
    static let KEY_YL_PRIO = "prio"
    static let KEY_YL_DID = "did"
    static let KEY_YL_PVID = "pvid"
    static let requiredKeys = [KEY_YL_PID,
                               KEY_YL_PVID,
                               KEY_YL_PRIO]
    static let optionalKeys = [KEY_YL_ID,
                               KEY_YL_ADVERTISER,
                               KEY_YL_CURL,
                               KEY_YL_FORMAT,
                               KEY_YL_DID]
    static let KEY_DFP_AID = "ylaid"
    static let KEY_DFP_PID = "ylpid"
    static let KEY_DFP_PVID = "ylpvid"
    static let KEY_DFP_YL = "yl"
    static let DEFAULT_TTL = 300000 // in milliseconds (1 minute -> 60000 milliseconds)
    static let KEY_JSON_CONFIG_ID = "id"
    static let KEY_JSON_CONFIG_SLOT = "slot"
    static let VALUE_IDFA_FALLBACK = "00000000-0000-0000-0000-000000000000"
    static let LOG_TAG_YIELDPROBE = "SOMYieldProbe"
    static let LOG_TAG_ADSLOT = "SOMYieldProbe SOIAdSlot"
    static let LOG_TAG_BID = "SOMYieldProbe SOMBid"
    static let LOG_TAG_GEO = "SOMYieldProbe SOMGeolocation"
    static let LOG_TAG_CON = "SOMYieldProbe SOMConnectivity"
    static let LOG_TAG_REACH = "SOMYieldProbe SOMReachability"
    static let OVERRIDE_BIDS_AT_UPDATE = false
    static let AUTOLOAD_AFTER_INIT = true
    static let UPDATE_IF_ALREADY_INIT = true
    static let REQUEST_BID_AFTER_GET_TARGETING = true
    static let USE_COOKIES = false
    static let ASSUME_CONNECTION_IF_UNKNOWN = true
    static let NPA_DEFAULT = false
    static let YP_NETWORK_STATE_2G = 4
    static let YP_NETWORK_STATE_2_5G = 4
    static let YP_NETWORK_STATE_3G = 5
    static let YP_NETWORK_STATE_3_5G = 5
    static let YP_NETWORK_STATE_4G = 6
    static let YP_NETWORK_STATE_UNKNOWN_WWAN = 3
    static let YP_NETWORK_STATE_UNKNOWN = 0
    static let YP_NETWORK_STATE_WIFI = 2
    static let YP_DEVICE_KEY_PHONE = "4"
    static let YP_DEVICE_KEY_TABLET = "5"
}
