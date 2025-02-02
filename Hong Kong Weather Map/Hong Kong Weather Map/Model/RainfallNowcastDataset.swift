//
//  RainfallNowcastDataset.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 24/3/2024.
//

import CoreLocation
import Foundation
import SwiftUI

enum RainfallLevel {
  case blue
  case green
  case yellow
  case orange
  case red

  var color: Color {

    switch self {
    case .blue:
      Color.blue
    case .green:
      Color.green
    case .yellow:
      Color.yellow
    case .orange:
      Color.orange
    case .red:
      Color.red
    }

  }

  static func getRainfallLevel(rainfall: Double) -> RainfallLevel? {

    switch rainfall {
    case 0.5..<2.5:
      return .blue
    case 2.5..<5:
      return .green
    case 5..<10:
      return .yellow
    case 10..<20:
      return .orange
    case 20..<999:
      return .red

    default:
      return nil
    }

  }

}

struct RainfallNowcastData: Identifiable {

  let updateTimestamp: Date
  let nowcastTimestamp: Date
  let latitude: Double
  let longitude: Double
  let rainfall: Double

  let id: String

  let coordinate: CLLocationCoordinate2D

  let rainfallLevel: RainfallLevel?

  init?(csvRow: [String]) {

    guard csvRow.count == 5 else { return nil }

    guard let timestamp = csvRow[0].convertTimestampStringToDate() else { return nil }

    updateTimestamp = timestamp

    guard let timestampOfNowcast = csvRow[1].convertTimestampStringToDate() else { return nil }

    nowcastTimestamp = timestampOfNowcast

    latitude = Double(csvRow[2]) ?? 0.0
    longitude = Double(csvRow[3]) ?? 0.0
    rainfall = Double(csvRow[4]) ?? 0.0

    id = UUID().uuidString

    coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

    rainfallLevel = RainfallLevel.getRainfallLevel(rainfall: rainfall)

  }
}

struct RainfallNowcastMergedGrid: Identifiable {

  let rainfallLevel: RainfallLevel

  let coordinates: [CLLocationCoordinate2D]

  let id: String

  init?(data: [RainfallNowcastData]) {

    guard !data.isEmpty, data.first!.rainfallLevel != nil else {
      return nil
    }

    self.rainfallLevel = data.first!.rainfallLevel!

    let maxLat = data.max(by: { $0.latitude < $1.latitude })?.latitude ?? 0.0
    let minLat = data.min(by: { $0.latitude < $1.latitude })?.latitude ?? 0.0
    let maxLong = data.max(by: { $0.longitude < $1.longitude })?.longitude ?? 0.0
    let minLong = data.min(by: { $0.longitude < $1.longitude })?.longitude ?? 0.0

    self.coordinates = [
      CLLocationCoordinate2D(latitude: minLat - 0.009, longitude: minLong - 0.01),
      CLLocationCoordinate2D(latitude: minLat - 0.009, longitude: maxLong + 0.01),
      CLLocationCoordinate2D(latitude: maxLat + 0.009, longitude: maxLong + 0.01),
      CLLocationCoordinate2D(latitude: maxLat + 0.009, longitude: minLong - 0.01),
    ]

    self.id = UUID().uuidString

  }
}

struct RainfallNowcastDataset {

  private(set) var sortedDatasetDict: [Date: [RainfallNowcastData]]

  private(set) var sortedMergedGridDict: [Date: [RainfallNowcastMergedGrid]]

  let creationTimestamp: Date

  init?(data: Data) {
    sortedMergedGridDict = [:]

    self.sortedDatasetDict = [:]

    self.creationTimestamp = Date()

    guard let csvString = String(data: data, encoding: .utf8) else {
      return nil
    }

    var rows =
      csvString
      .split(separator: "\n")
      .map { substring in
        let row = substring.split(separator: ",").map { string in
          String(string)
        }

        return row
      }.compactMap { row in
        RainfallNowcastData(csvRow: row)
      }

    if rows.count < 2 { return }

    var dict: [Date: NSMutableArray] = [:]

    for i in (1..<rows.count) {

      let dataRow = rows[i]

      let dataRowTimestamp = dataRow.nowcastTimestamp

      var dataRowArrayOfTheTime = dict[dataRowTimestamp] ?? NSMutableArray()

      if dataRowArrayOfTheTime.count == 0 {
        dict[dataRowTimestamp] = dataRowArrayOfTheTime
      }

      dataRowArrayOfTheTime.add(dataRow)

    }

    for key in dict.keys {

      let nsArray = dict[key] as! [RainfallNowcastData]

      sortedDatasetDict[key] = nsArray.sorted(by: { a, b in

        if a.latitude == b.latitude {
          return a.longitude > b.longitude
        }

        return a.latitude > b.latitude
      })

      var mergedGridArray: [RainfallNowcastMergedGrid] = []

      var tmp: [RainfallNowcastData] = []

      for data in sortedDatasetDict[key]!
      where data.latitude < CLLocation.HKNorthEastCoord.coordinate.latitude
        && data.latitude > CLLocation.HKSouthWestCoord.coordinate.latitude
        && data.longitude < CLLocation.HKNorthEastCoord.coordinate.longitude
        && data.longitude > CLLocation.HKSouthWestCoord.coordinate.longitude
      {

        guard data.rainfallLevel != nil else {
          if let gridData = RainfallNowcastMergedGrid(data: tmp) {
            mergedGridArray.append(gridData)
          }
          tmp = []
          continue
        }

        if tmp.isEmpty
          || (tmp.last!.latitude == data.latitude && tmp.last!.rainfallLevel == data.rainfallLevel
            && tmp.last!.nowcastTimestamp == data.nowcastTimestamp)
        {
          tmp.append(data)
          continue
        }

        if let gridData = RainfallNowcastMergedGrid(data: tmp) {
          mergedGridArray.append(gridData)
        }
        tmp = [data]

      }

      if let gridData = RainfallNowcastMergedGrid(data: tmp) {
        mergedGridArray.append(gridData)
      }

      sortedMergedGridDict[key] = mergedGridArray

    }

  }

  func getRainfallRangeForLocation(
    location: CLLocationCoordinate2D, southWestBoundary: CLLocationCoordinate2D,
    northEastBoundary: CLLocationCoordinate2D
  ) -> (Double, Double)? {

    guard
      location.latitude <= northEastBoundary.latitude
        && location.latitude >= southWestBoundary.latitude
        && location.longitude >= southWestBoundary.longitude
        && location.longitude <= northEastBoundary.longitude
    else {
      return nil
    }

    var result: [RainfallNowcastData] = []

    for dataset in self.sortedDatasetDict.values {

      for data in dataset {

        if location.latitude <= data.coordinate.northEastCoordOfDrawingSquare.latitude
          && location.latitude >= data.coordinate.southWestCoordOfDrawingSquare.latitude
          && location.longitude >= data.coordinate.southWestCoordOfDrawingSquare.longitude
          && location.longitude <= data.coordinate.northEastCoordOfDrawingSquare.longitude
        {
          result.append(data)
          break
        }

      }

    }

    result.sort { a, b in

      return a.rainfall < b.rainfall

    }

    if result.isEmpty {
      return nil
    }

    return (result.first?.rainfall ?? 0, result.last?.rainfall ?? 0)

  }

}
