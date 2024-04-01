//
//  CLLocationCoordinate2D+extension.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 27/3/2024.
//

import CoreLocation
import Foundation

extension CLLocationCoordinate2D {

  var southWestCoordOfDrawingSquare: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: self.latitude - 0.009, longitude: self.longitude - 0.01)
  }

  var northEastCoordOfDrawingSquare: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: self.latitude + 0.009, longitude: self.longitude + 0.01)
  }

  func coordinatesForDrawingSquare() -> [CLLocationCoordinate2D] {

    [
      southWestCoordOfDrawingSquare,
      CLLocationCoordinate2D(latitude: self.latitude - 0.009, longitude: self.longitude + 0.01),
      northEastCoordOfDrawingSquare,
      CLLocationCoordinate2D(latitude: self.latitude + 0.009, longitude: self.longitude - 0.01),
    ]
  }

}
