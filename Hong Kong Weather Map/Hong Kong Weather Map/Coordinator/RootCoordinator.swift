//
//  RootCoordinator.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 1/4/2024.
//

import Foundation

enum Tab: String, Hashable {
  case map
  case summary
}

class RootCoordinator: ObservableObject {

  @Published
  var selectedTab: Tab = .map

  func makeRainfallNowcastMapViewModel() -> RainfallNowcastMapViewModel {

    let vm = RainfallNowcastMapViewModel()
    //    vm.delegate = self

    return vm
  }

}

//extension RootCoordinator: RainfallNowcastMapViewModelDelegate {

//}
