//
//  CLLocationManager + Extension.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 24/2/2024.
//

import CoreLocation
import Foundation

protocol CLLocationManagerType {
  func requestWhenInUseAuthorization()
  func startUpdatingLocation()
  var delegate: CLLocationManagerDelegate? { get set }
}

extension CLLocationManager: CLLocationManagerType {

}
