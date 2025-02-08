//
//  WeatherWarningViewModel.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 20/4/2024.
//

import Combine
import Foundation

@MainActor
class WeatherWarningViewModel: ObservableObject {
  var weatherWarningDataset: WeatherWarningDataset

  @Published
  var selection: String

  var timerTask: Task<Void, Never>?

  private var cancellables: Set<AnyCancellable> = Set()

  init(weatherWarningDataset: WeatherWarningDataset) {
    self.weatherWarningDataset = weatherWarningDataset
    self.selection = self.weatherWarningDataset.activeWarnings.first?.id ?? ""

    initiateWarningRotateTimer()

  }

  func initiateWarningRotateTimer() {

    guard weatherWarningDataset.activeWarnings.count > 1 else { return }

    timerTask?.cancel()

    timerTask = Task { [weak self] in

      while !Task.isCancelled {

        guard let self else { return }

        if self.selection == self.weatherWarningDataset.activeWarnings.last?.id {
          self.selection = self.weatherWarningDataset.activeWarnings.first?.id ?? ""
          try? await Task.sleep(for: .seconds(5))
          continue
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

        try? await Task.sleep(for: .seconds(5))

      }

    }

  }

}
