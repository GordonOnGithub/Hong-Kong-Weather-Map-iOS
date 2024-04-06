//
//  MapLegendView.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 1/4/2024.
//

import Foundation
import SwiftUI

struct MapLegendView: View {
  var body: some View {

    VStack(spacing: 10) {

      Text("Map Legend").underline().foregroundStyle(.primary)
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 5) {

          Rectangle().fill(RainfallLevel.blue.color).frame(width: 20, height: 20)

          Text("0.5mm - 2.5mm").foregroundStyle(.primary)

        }

        HStack(spacing: 5) {

          Rectangle().fill(RainfallLevel.green.color).frame(width: 20, height: 20)

          Text("2.5mm - 5mm").foregroundStyle(.primary)

        }

        HStack(spacing: 5) {

          Rectangle().fill(RainfallLevel.yellow.color).frame(width: 20, height: 20)

          Text("5mm - 10mm").foregroundStyle(.primary)

        }

        HStack(spacing: 5) {

          Rectangle().fill(RainfallLevel.orange.color).frame(width: 20, height: 20)

          Text("10mm - 20mm").foregroundStyle(.primary)

        }

        HStack(spacing: 5) {

          Rectangle().fill(RainfallLevel.orange.color).frame(width: 20, height: 20)

          Text("10mm - 20mm").foregroundStyle(.primary)

        }

        HStack(spacing: 5) {

          Rectangle().fill(RainfallLevel.red.color).frame(width: 20, height: 20)

          Text(" > 20mm").foregroundStyle(.primary)

        }
      }

    }.padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))

  }
}
