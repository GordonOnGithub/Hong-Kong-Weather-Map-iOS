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
      Color.blue.opacity(0.6)
    case .green:
      Color.green.opacity(0.6)
    case .yellow:
      Color.yellow.opacity(0.6)
    case .orange:
      Color.orange.opacity(0.6)
    case .red:
      Color.red.opacity(0.6)
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

struct RainfallNowcastDataset {

  private(set) var sortedDatasetDict: [Date: [RainfallNowcastData]]

  let creationTimestamp: Date

  init?(data: Data) {

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
