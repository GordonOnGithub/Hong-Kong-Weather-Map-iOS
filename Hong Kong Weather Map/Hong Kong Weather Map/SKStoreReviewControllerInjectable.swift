//
//  SKStoreReviewControllerInjectable.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 18/2/2024.
//

import Foundation
import StoreKit
import UIKit

@MainActor
protocol SKStoreReviewControllerInjectableType {
  func requestReview()
}

@MainActor
class SKStoreReviewControllerInjectable: SKStoreReviewControllerInjectableType {

  let uiApplication: UIApplicationType

  init(uiApplication: UIApplicationType = UIApplication.shared) {
    self.uiApplication = uiApplication
  }

  func requestReview() {
    if let scene = uiApplication.connectedScenes.first(where: {
      $0.activationState == .foregroundActive
    }) as? UIWindowScene {
      SKStoreReviewController.requestReview(in: scene)
    }
  }

}
