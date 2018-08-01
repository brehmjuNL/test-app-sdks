//
//  SOMGeolocation.swift
//  SOMYieldProbeSDK
//
//  Created by Julian Brehm on 2018-07-26.
//  Copyright © 2018 SevenOne Media. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class SOMGeolocation: NSObject {
    
    static let sharedService = SOMGeolocation() // Singleton
    
    var locationManager: CLLocationManager!
    var locationPermissionGranted = false // Indicates if the location permission is granted.
    var locationUpdateEnabled = false // Indicates if location updates are enabled.
    
    var latitude: Double!
    var longitude: Double!
    
    override init(){
        super.init()
        SOMYieldProbeLogger.log(String(format: "%@: Constructor called, initialize...", SOMConfig.LOG_TAG_GEO))
        setup()
    }
    
    func setup(){
        let status  = CLLocationManager.authorizationStatus()
        latitude = nil
        longitude = nil
        if locationManager == nil {
            SOMYieldProbeLogger.log(String(format: "%@: Create new location manager...", SOMConfig.LOG_TAG_GEO))
            locationManager = CLLocationManager()
        }
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        switch status {
        case .restricted:
            locationPermissionGranted = false
            locationUpdateEnabled = false
            SOMYieldProbeLogger.log(String(format: "%@: Authorization status restricted.", SOMConfig.LOG_TAG_GEO))
        case .denied:
            locationPermissionGranted = false
            locationUpdateEnabled = false
            SOMYieldProbeLogger.log(String(format: "%@: Authorization status denied.", SOMConfig.LOG_TAG_GEO))
        case .notDetermined:
            locationPermissionGranted = false
            locationUpdateEnabled = false
            // Request location authorization
            SOMYieldProbeLogger.log(String(format: "%@: Authorization status notDetermined.", SOMConfig.LOG_TAG_GEO))
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            // Update location data periodically
            locationManager.startMonitoringSignificantLocationChanges()
            // Request a location update
            locationManager.requestLocation()
            locationPermissionGranted = true
            locationUpdateEnabled = true
            SOMYieldProbeLogger.log(String(format: "%@: Authorization status authorizedAlways.", SOMConfig.LOG_TAG_GEO))
        case .authorizedWhenInUse:
            // Update location data periodically
            locationManager.startMonitoringSignificantLocationChanges()
            // Request a location update
            locationManager.requestLocation()
            locationPermissionGranted = true
            locationUpdateEnabled = true
            SOMYieldProbeLogger.log(String(format: "%@: Authorization status authorizedWhenInUse.", SOMConfig.LOG_TAG_GEO))
        }
    }
    func isLocationPermissionGranted() -> Bool {
        return locationPermissionGranted
    }
    
    func isLocationUpdateEnabled() -> Bool {
        return locationUpdateEnabled
    }
}

extension SOMGeolocation: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Process the received location update
        SOMYieldProbeLogger.log(String(format: "%@: Callback didUpdateLocations triggered.", SOMConfig.LOG_TAG_GEO))
        let location = locations.last!
        let eventDate = location.timestamp
        let howRecent = eventDate.timeIntervalSinceNow // In seconds
        if fabs(howRecent) < 15.0 { //
            // If the event is recent, update lat/long properties
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            SOMYieldProbeLogger.log(String(format: "%@: Current location: %@", SOMConfig.LOG_TAG_GEO, location.debugDescription))
        } else {
            SOMYieldProbeLogger.log(String(format: "%@: Callback didUpdateLocations received an old event.", SOMConfig.LOG_TAG_GEO))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied || status == .restricted || status == .notDetermined {
            manager.stopMonitoringSignificantLocationChanges()
            latitude = nil
            longitude = nil
            locationPermissionGranted = false
            locationUpdateEnabled = false
            SOMYieldProbeLogger.log(String(format: "%@: Location authorization status changed to non granted.", SOMConfig.LOG_TAG_GEO))
        } else {
            // Location permission granted, update location data periodically
            manager.startMonitoringSignificantLocationChanges()
            // Request a location update
            locationManager.requestLocation()
            locationPermissionGranted = true
            locationUpdateEnabled = true
            SOMYieldProbeLogger.log(String(format: "%@: Location authorization status changed to granted.", SOMConfig.LOG_TAG_GEO))
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopMonitoringSignificantLocationChanges()
        latitude = nil
        longitude = nil
        locationUpdateEnabled = false
        SOMYieldProbeLogger.log(String(format: "%@: Callback didFailWithError %@.", SOMConfig.LOG_TAG_GEO, error.localizedDescription))
    }
}
