//
//  WeatherWarningViewModel.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 20/4/2024.
//

import Combine
import Foundation

class WeatherWarningViewModel: ObservableObject {
  var weatherWarningDataset: WeatherWarningDataset

  @Published
  var selection: String

  var timer: Timer?

  private var cancellables: Set<AnyCancellable> = Set()

  init(weatherWarningDataset: WeatherWarningDataset) {
    self.weatherWarningDataset = weatherWarningDataset
    self.selection = self.weatherWarningDataset.activeWarnings.first?.id ?? ""

    initiateWarningRotateTimer()

    $selection.sink { [weak self] _ in
      self?.initiateWarningRotateTimer()
    }.store(in: &cancellables)
  }

  func initiateWarningRotateTimer() {

    guard weatherWarningDataset.activeWarnings.count > 1 else { return }

    timer?.invalidate()

    timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in

      guard let self else { return }

      if self.selection == self.weatherWarningDataset.activeWarnings.last?.id {
        self.selection = self.weatherWarningDataset.activeWarnings.first?.id ?? ""
        return
      }

      var found = false

      for warning in weatherWarningDataset.activeWarnings {
        if warning.id == selection {
          found = true
          continue
        }

        if found {
          self.selection = warning.id
          break
        }
      }
    }
  }

}
