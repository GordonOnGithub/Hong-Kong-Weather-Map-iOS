//
//  Date+Extension.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 29/3/2024.
//

import Foundation

extension Date: Identifiable {
  public var id: String {
    self.ISO8601Format()
  }

}
