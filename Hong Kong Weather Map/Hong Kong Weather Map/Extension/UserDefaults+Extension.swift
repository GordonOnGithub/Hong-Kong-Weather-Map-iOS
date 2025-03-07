//
//  UserDefaults+Extension.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 3/2/2024.
//

import Foundation

protocol UserDefaultsType {

  func string(forKey: String) -> String?

  func object(forKey defaultName: String) -> Any?

  func setValue(_ value: Any?, forKey key: String)
}

extension UserDefaults: UserDefaultsType {
}

enum UserDefaultsKeys: String {

  case shownMapPinningTipKey = "shownMapPinningTip"
  case shownMapUnpinningTipKey = "shownMapUnpinningTip"
  case shownAddMapPinTipKey = "shownAddMapPinTip"
  case shownAutoSaveTipKey = "shownAutoSaveTip"
  case shownSelectionModeToggleTipKey = "shownSelectionModeToggleTip"

  case isEarlyUserKey = "isEarlyUser"
  case launchAppCountKey = "launchAppCount"
  case didAskForReviewKey = "didAskForReview"

  case didAskForSupportKey = "didAskForSupport"

  case measurementLocaleStringKey = "measurementLocaleString"
  case hideLabelsWhenZoomingOutKey = "hideLabelsWhenZoomingOut"
  case mapStyleKey = "mapStyle"
}
