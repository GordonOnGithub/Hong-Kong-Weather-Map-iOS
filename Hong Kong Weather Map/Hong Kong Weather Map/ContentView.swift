//
//  ContentView.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 24/3/2024.
//

import Combine
import SwiftUI

struct ContentView: View {
  @StateObject
  var viewModel = RainfallNowcastMapViewModel()

  var body: some View {
    VStack {
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()

  }
}

#Preview {
  ContentView()
}
