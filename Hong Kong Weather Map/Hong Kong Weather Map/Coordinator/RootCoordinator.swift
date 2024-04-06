//
//  RootCoordinator.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 1/4/2024.
//

import Foundation

enum RootCoordinatorSheetRoute: Identifiable {

  case mapLegend

  var id: String {
    switch self {
    case .mapLegend:
      return "mapLegend"
    }

  }

}

class RootCoordinator: ObservableObject {
  @Published
  var sheetRoute: RootCoordinatorSheetRoute?

  func makeRainfallNowcastMapViewModel() -> RainfallNowcastMapViewModel {

    let vm = RainfallNowcastMapViewModel()
    vm.delegate = self

    return vm
  }
}

extension RootCoordinator: RainfallNowcastMapViewModelDelegate {
  func rainfallNowcastMapViewModelDidRequestShowMapLegend(_ viewModel: RainfallNowcastMapViewModel)
  {
    sheetRoute = .mapLegend
  }

}
