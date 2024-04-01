//
//  String+Extension.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 27/3/2024.
//

import Foundation

extension String {

  func leftPadded(length: Int, character: Character) -> String {

    let paddingSize = length - self.count

    guard paddingSize > 0 else { return self }

    var result = ""

    for i in 0..<paddingSize {

      result.append(character)
    }

    result.append(self)

    return result

  }

  func convertTimestampStringToDate() -> Date? {

    guard self.count == 12 else { return nil }

    let timestampYear = Int(self[self.startIndex...self.index(self.startIndex, offsetBy: 3)])

    let timestampMonth = Int(
      self[self.index(self.startIndex, offsetBy: 4)...self.index(self.startIndex, offsetBy: 5)])

    let timestampDay = Int(
      self[self.index(self.startIndex, offsetBy: 6)...self.index(self.startIndex, offsetBy: 7)])

    let timestampHour = Int(
      self[self.index(self.startIndex, offsetBy: 8)...self.index(self.startIndex, offsetBy: 9)])

    let timestampMinute = Int(
      self[self.index(self.startIndex, offsetBy: 10)...self.index(self.startIndex, offsetBy: 11)])

    var timestampComponents = DateComponents()

    timestampComponents.year = timestampYear
    timestampComponents.month = timestampMonth
    timestampComponents.day = timestampDay
    timestampComponents.hour = timestampHour
    timestampComponents.minute = timestampMinute

    return Calendar(identifier: .gregorian).date(from: timestampComponents)
  }

}
