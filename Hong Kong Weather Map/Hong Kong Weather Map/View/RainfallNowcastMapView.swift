//
//  RainfallNowcastMapView.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 27/3/2024.
//

import Foundation
import MapKit
import SwiftUI

struct RainfallNowcastMapView: View {

  @StateObject
  var viewModel: RainfallNowcastMapViewModel = RainfallNowcastMapViewModel()

  var body: some View {
    VStack {
      GeometryReader { reader in
        Map(
          position: .constant(
            .camera(.init(centerCoordinate: viewModel.mapCenter, distance: 180000))),
          bounds: viewModel.mapBound, interactionModes: [.pan, .zoom]
        ) {

          if let rainfallNowcastDataset = viewModel.rainfallNowcastDataset,
            let selectedTimestamp = viewModel.selectedTimestamp,
            let datasetOfSelectedTimestamp = rainfallNowcastDataset.sortedDatasetDict[
              selectedTimestamp]?.filter({ data in
                data.rainfallLevel != nil && viewModel.isWithinHKBoundary(coord: data.coordinate)
              })
          {

            ForEach(datasetOfSelectedTimestamp) { data in
              MapPolygon(coordinates: data.coordinate.coordinatesForDrawingSquare())
                .foregroundStyle(data.rainfallLevel!.color)
            }

            if viewModel.autoplayTimer == nil {
              MapPolygon(coordinates: [
                viewModel.HKNorthEastCoord.coordinate,

                CLLocationCoordinate2D(
                  latitude: viewModel.HKSouthWestCoord.coordinate.latitude,
                  longitude: viewModel.HKNorthEastCoord.coordinate.longitude),

                viewModel.HKSouthWestCoord.coordinate,

                CLLocationCoordinate2D(
                  latitude: viewModel.HKNorthEastCoord.coordinate.latitude,
                  longitude: viewModel.HKSouthWestCoord.coordinate.longitude),

              ]).stroke(.black, lineWidth: 1)
                .foregroundStyle(.clear)
            }
          }

          UserAnnotation()

        }.mapControls {
          if viewModel.hasLocationPermission {
            MapUserLocationButton()
          }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .frame(height: reader.size.width)
      }

      Spacer()

      if !viewModel.datasetTimestampList.isEmpty,
        let selectedTimestamp = viewModel.selectedTimestamp
      {

        HStack {

          Button(
            action: {

              viewModel.fetchRainfallNowcastData()

            },
            label: {
              Text("Refresh")
                .font(.system(size: 20))
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            }
          ).foregroundStyle(.white)
            .background(.green)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .disabled(viewModel.isFetching)

          Menu {

            ForEach(viewModel.datasetTimestampList) { date in

              Button(viewModel.getTimeOfTheDay(date)) {
                viewModel.selectedTimestamp = date
              }

            }

          } label: {

            Text(viewModel.getTimeOfTheDay(selectedTimestamp))
              .font(.system(size: 20))
              .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
          }
          .foregroundStyle(.white)
          .background(.blue)
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .disabled(viewModel.autoplayTimer != nil)

          Button(
            action: {

              viewModel.onPlayButtonClicked()

            },
            label: {
              if viewModel.autoplayTimer == nil {
                Text("Play")
                  .font(.system(size: 20))
                  .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
              } else {
                Text("Stop")
                  .font(.system(size: 20))
                  .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
              }
            }
          ).foregroundStyle(.white)
            .background(.green)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .disabled(viewModel.isFetching)
        }
        Spacer()
      }
    }
  }
}
