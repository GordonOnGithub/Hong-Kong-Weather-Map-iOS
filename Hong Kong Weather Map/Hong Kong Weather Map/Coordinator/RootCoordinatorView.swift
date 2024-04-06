//
//  RootCoordinatorView.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 1/4/2024.
//

import Foundation
import SwiftUI

struct RootCoordinatorView: View {

  @StateObject
  var coordinator: RootCoordinator = RootCoordinator()

  var body: some View {
    NavigationStack {
      RainfallNowcastMapView(viewModel: coordinator.makeRainfallNowcastMapViewModel())
    }.sheet(item: $coordinator.sheetRoute) { route in

      switch route {
      case .mapLegend:
        MapLegendView()

      }

    }
  }
}
