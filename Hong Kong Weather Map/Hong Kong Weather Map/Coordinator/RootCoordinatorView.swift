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

    RainfallNowcastMapView(viewModel: coordinator.makeRainfallNowcastMapViewModel())

    //    NavigationStack {
    //
    //      TabView(selection: $coordinator.selectedTab) {
    //        RainfallNowcastMapView(viewModel: coordinator.makeRainfallNowcastMapViewModel())
    //          .tabItem({
    //            Label("Map", systemImage: "map")
    //          }).tag(Tab.map)
    //
    //        WeatherSummaryView(viewModel: coordinator.makeWeatherSummaryViewModel())
    //          .tabItem({
    //            Label("Summary", systemImage: "info.circle")
    //          }).tag(Tab.summary)
    //
    //      }
    //
    //    }
  }
}
