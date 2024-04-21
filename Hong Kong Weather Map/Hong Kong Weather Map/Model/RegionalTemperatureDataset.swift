//
//  RegionalTemperatureDataset.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 21/4/2024.
//

import CoreLocation
import Foundation

struct RegionalTemperatureDataset {

  var dataDict: [String: String]

  init?(data: Data) {

    self.dataDict = [:]

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
      }.filter { row in
        row.count == 3
      }

    if rows.count < 2 { return }

    for i in 1..<rows.count {
      let row = rows[i]

      dataDict[row[1]] = row[2]

    }

  }

  static func getWeatherStationPosition(locationName: String) -> CLLocationCoordinate2D? {

    switch locationName {

    case "Chek Lap Kok":
      return CLLocationCoordinate2D(latitude: 22.3094444, longitude: 113.9219444)
    case "Cheung Chau":
      return CLLocationCoordinate2D(latitude: 22.2011111, longitude: 114.0266667)
    case "Clear Water Bay":
      return CLLocationCoordinate2D(latitude: 22.2633333, longitude: 114.2997222)
    case "Happy Valley":
      return CLLocationCoordinate2D(latitude: 22.2705556, longitude: 114.1836111)
    case "HK Observatory":
      return CLLocationCoordinate2D(latitude: 22.3019444, longitude: 114.1741667)
    case "HK Park":
      return CLLocationCoordinate2D(latitude: 22.2783333, longitude: 114.1622222)
    case "Kai Tak Runway Park":
      return CLLocationCoordinate2D(latitude: 22.3047222, longitude: 114.2169444)
    case "Kau Sai Chau":
      return CLLocationCoordinate2D(latitude: 22.3702778, longitude: 114.3125)
    case "King's Park":
      return CLLocationCoordinate2D(latitude: 22.3119444, longitude: 114.1727778)
    case "Kowloon City":
      return CLLocationCoordinate2D(latitude: 22.335, longitude: 114.1847222)
    case "Kwun Tong":
      return CLLocationCoordinate2D(latitude: 22.3186111, longitude: 114.2247222)
    case "Lau Fau Shan":
      return CLLocationCoordinate2D(latitude: 22.4688889, longitude: 113.9836111)
    case "Ngong Ping":
      return CLLocationCoordinate2D(latitude: 22.2586111, longitude: 113.9127778)
    case "Pak Tam Chung":
      return CLLocationCoordinate2D(latitude: 22.4027778, longitude: 114.3230556)
    case "Peng Chau":
      return CLLocationCoordinate2D(latitude: 22.2911111, longitude: 114.0433333)
    case "Sai Kung":
      return CLLocationCoordinate2D(latitude: 22.3755556, longitude: 114.2744444)
    case "Sha Tin":
      return CLLocationCoordinate2D(latitude: 22.4025, longitude: 114.21)
    case "Sham Shui Po":
      return CLLocationCoordinate2D(latitude: 22.3358333, longitude: 114.1369444)
    case "Shau Kei Wan":
      return CLLocationCoordinate2D(latitude: 22.2816667, longitude: 114.2361111)
    case "Shek Kong":
      return CLLocationCoordinate2D(latitude: 22.4361111, longitude: 114.0847222)
    case "Sheung Shui":
      return CLLocationCoordinate2D(latitude: 22.5019444, longitude: 114.1111111)
    case "Stanley":
      return CLLocationCoordinate2D(latitude: 22.2141667, longitude: 114.2186111)
    case "Ta Kwu Ling":
      return CLLocationCoordinate2D(latitude: 22.5286111, longitude: 114.1566667)
    case "Tai Lung":
      return CLLocationCoordinate2D(latitude: 22.4847222, longitude: 114.1175)
    case "Tai Mei Tuk":
      return CLLocationCoordinate2D(latitude: 22.4752778, longitude: 114.2375)
    case "Tai Mo Shan":
      return CLLocationCoordinate2D(latitude: 22.4105556, longitude: 114.1244444)
    case "Tai Po":
      return CLLocationCoordinate2D(latitude: 22.4461111, longitude: 114.1788889)
    case "Tate's Cairn":
      return CLLocationCoordinate2D(latitude: 22.3577778, longitude: 114.2177778)
    case "The Peak":
      return CLLocationCoordinate2D(latitude: 22.2641667, longitude: 114.155)
    case "Tseung Kwan O":
      return CLLocationCoordinate2D(latitude: 22.3158333, longitude: 114.2555556)
    case "Tsing Yi":
      return CLLocationCoordinate2D(latitude: 22.3441667, longitude: 114.11)
    case "Tsuen Wan Ho Koon":
      return CLLocationCoordinate2D(latitude: 22.3836111, longitude: 114.1077778)
    case "Tsuen Wan Shing Mun Valley":
      return CLLocationCoordinate2D(latitude: 22.3755556, longitude: 114.1266667)
    case "Tuen Mun":
      return CLLocationCoordinate2D(latitude: 22.3858333, longitude: 113.9641667)
    case "Waglan Island":
      return CLLocationCoordinate2D(latitude: 22.1822222, longitude: 114.3033333)
    case "Wetland Park":
      return CLLocationCoordinate2D(latitude: 22.4666667, longitude: 114.0088889)
    case "Wong Chuk Hang":
      return CLLocationCoordinate2D(latitude: 22.2477778, longitude: 114.1736111)
    case "Wong Tai Sin":
      return CLLocationCoordinate2D(latitude: 22.3394444, longitude: 114.2052778)
    case "Yuen Long Park":
      return CLLocationCoordinate2D(latitude: 22.4408333, longitude: 114.0183333)
    default:
      return nil
    }

  }

}
