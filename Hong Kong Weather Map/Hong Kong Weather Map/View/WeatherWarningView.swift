//
//  WeatherWarningView.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 20/4/2024.
//

import Foundation
import SwiftUI

struct WeatherWarningView: View {

  @StateObject
  var viewModel: WeatherWarningViewModel

  var body: some View {
    Group {

      VStack {
        HStack {
          Image(systemName: "exclamationmark.triangle").foregroundStyle(.black)

          Text(
            viewModel.weatherWarningDataset.activeWarnings.count > 1
              ? "\(viewModel.weatherWarningDataset.activeWarnings.count) Weather Warnings"
              : "Weather Warning"
          )
          .bold()
          Spacer()
        }.frame(height: 30)
        Divider()
        TabView(selection: $viewModel.selection) {

          ForEach(viewModel.weatherWarningDataset.activeWarnings) { warning in
            VStack {
              HStack {
                Text((warning.warningCodeDescription ?? "") + " " + warning.description)
                  .padding(EdgeInsets(top: 5, leading: 0, bottom: 10, trailing: 0))
                Spacer()
              }
              Spacer()
            }.tag(warning.id)
          }

        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .automatic))
        .frame(height: 65)
        .padding(EdgeInsets(top: 0, leading: 0, bottom: -20, trailing: 0))

      }
      .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
    }
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(.yellow)
    )
    .frame(height: 100)
  }
}
