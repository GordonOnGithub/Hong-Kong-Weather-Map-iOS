//
//  UIApplication+Extension.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 3/2/2024.
//

import Foundation
import UIKit

@MainActor
protocol UIApplicationType {
  func canOpenURL(_ url: URL) -> Bool
  func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any]) async -> Bool
  var connectedScenes: Set<UIScene> { get }
}

extension UIApplication: UIApplicationType {

}
