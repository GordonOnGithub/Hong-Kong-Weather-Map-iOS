//
//  WeatherWarningDataset.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 6/4/2024.
//

import Foundation

struct WeatherWarning: Identifiable {

  let warningSummaryCode: String

  let description: String

  let warningCode: String

  let actionCode: String

  var id: String {

    self.warningSummaryCode + "_" + self.warningCode
  }

  var warningCodeDescription: String? {

    switch warningCode {
    case "WRAINA":
      return "Amber"
    case "WRAINR":
      return "Red"
    case "WRAINB":
      return "Black"
    case "TC1":
      return "No. 1"
    case "TC3":
      return "No. 3"
    case "TC8NE":
      return "No. 8 North East"
    case "TC8SE":
      return "No. 8 South East"
    case "TC8SW":
      return "No. 8 South West"
    case "TC8NW":
      return "No. 8 North West"
    case "TC9":
      return "No. 9"
    case "TC10":
      return "No. 10"
    case "WFIREY":
      return "Yellow Fire"
    case "WFIRER":
      return "Red Fire"

    default:
      return nil

    }
  }

  var priority: Int {

    switch warningCode {
    case "WTCSGNL":
      return 0
    case "WRAIN":
      return 1
    case "WTS", "WL", "WCOLD", "WHOT":
      return 2

    default:
      return Int.max
    }

  }
}

struct WeatherWarningDataset {

  let activeWarnings: [WeatherWarning]

  init(data: Data) {

    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      activeWarnings = []
      return
    }

    activeWarnings = json.keys.compactMap({ key in

      guard let detail = json[key] as? [String: String],
        let description = detail["name"],
        let warningCode = detail["code"],
        let actionCode = detail["actionCode"],
        actionCode != "CANCEL"
      else {
        return nil
      }

      return WeatherWarning(
        warningSummaryCode: key, description: description, warningCode: warningCode,
        actionCode: actionCode)

    }).sorted(by: { a, b in
      a.priority > b.priority
    })

  }

}
