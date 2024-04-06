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

  @Environment(\.colorScheme) var colorScheme

  @StateObject
  var viewModel: RainfallNowcastMapViewModel

  var body: some View {
    GeometryReader { reader in

      VStack {
        HStack {
          Spacer()

          viewModel.currentLocationRainfallRangeMessage.icon

          Text(viewModel.currentLocationRainfallRangeMessage.message).multilineTextAlignment(
            .leading)
          Spacer()
        }.background(viewModel.currentLocationRainfallRangeMessage.color)
          .padding(
            EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
          )
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

        if !viewModel.isFetching {

          HStack {

            if viewModel.rainfallNowcastDataset != nil {

              Text(
                "Last update: \(viewModel.rainfallNowcastDataset?.creationTimestamp.description ?? "")"
              )
              .font(.system(size: 12))

              Button(
                action: {
                  viewModel.onMapLegendButtonClicked()
                },
                label: {
                  HStack {
                    Image(systemName: "info.circle")
                    Text("Legend")
                  }.padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                    .overlay(
                      RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.blue, lineWidth: 1)
                    )
                }
              ).buttonStyle(.plain)
                .foregroundStyle(.blue)

            }

          }

          HStack {

            Button(
              action: {
                viewModel.fetchRainfallNowcastData()
              },
              label: {
                HStack {
                  Image(systemName: "arrow.clockwise.circle")

                  Text("Refresh")
                    .font(.system(size: 20))

                }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
              }
            ).foregroundStyle(.white)
              .background(.green)
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .disabled(viewModel.isFetching)

            if !viewModel.datasetTimestampList.isEmpty,
              let selectedTimestamp = viewModel.selectedTimestamp
            {
              Menu {

                ForEach(viewModel.datasetTimestampList) { date in

                  Button(
                    action: {
                      viewModel.selectedTimestamp = date

                    },
                    label: {

                      if date == viewModel.selectedTimestamp {
                        HStack {

                          Image(systemName: "checkmark.circle")
                          Text(viewModel.getTimeOfTheDay(date))
                            .bold()
                          Spacer()
                        }
                      } else {
                        Text(viewModel.getTimeOfTheDay(date))

                      }

                    })

                }

              } label: {
                HStack {
                  Image(systemName: "clock")

                  Text(viewModel.getTimeOfTheDay(selectedTimestamp))
                    .font(.system(size: 20))
                    .multilineTextAlignment(.leading)
                    .frame(width: 60)

                }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
              }
              .foregroundStyle(.white)
              .background(viewModel.autoplayTimer == nil ? .blue : .gray)
              .clipShape(RoundedRectangle(cornerRadius: 5))
              .disabled(viewModel.autoplayTimer != nil)

              Button(
                action: {

                  viewModel.onPlayButtonClicked()

                },
                label: {
                  HStack {

                    if viewModel.autoplayTimer == nil {
                      Image(systemName: "play.circle")

                      Text("Play")
                        .font(.system(size: 20))

                    } else {

                      Image(systemName: "stop.circle")

                      Text("Stop")
                        .font(.system(size: 20))
                    }
                  }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                }
              ).foregroundStyle(.white)
                .background(viewModel.autoplayTimer == nil ? .green : .red)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .disabled(viewModel.isFetching)
            }
          }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }

        Spacer()
      }.overlay {
        if viewModel.isFetching {
          ZStack {
            Rectangle().fill(.black.opacity(0.3))
            ProgressView {
              Text("Loading...")
            }
          }
        }

      }
    }
  }

  //  var mapLegendOverlay: some View {
  //
  //      // TODO: check if overlay has impact on performance
  //    ZStack {
  //
  //      Rectangle().fill(.black.opacity(0.3))
  //
  //      RoundedRectangle(cornerRadius: 5).fill(colorScheme == .dark ? .black : .white)
  //        .frame(width: 200, height: 280)
  //
  //      VStack(spacing: 10) {
  //
  //        Text("Map Legend").underline().foregroundStyle(.primary)
  //        VStack(alignment: .leading, spacing: 10) {
  //          HStack(spacing: 5) {
  //
  //            Rectangle().fill(RainfallLevel.blue.color).frame(width: 20, height: 20)
  //
  //            Text("0.5mm - 2.5mm").foregroundStyle(.primary)
  //
  //          }
  //
  //          HStack(spacing: 5) {
  //
  //            Rectangle().fill(RainfallLevel.green.color).frame(width: 20, height: 20)
  //
  //            Text("2.5mm - 5mm").foregroundStyle(.primary)
  //
  //          }
  //
  //          HStack(spacing: 5) {
  //
  //            Rectangle().fill(RainfallLevel.yellow.color).frame(width: 20, height: 20)
  //
  //            Text("5mm - 10mm").foregroundStyle(.primary)
  //
  //          }
  //
  //          HStack(spacing: 5) {
  //
  //            Rectangle().fill(RainfallLevel.orange.color).frame(width: 20, height: 20)
  //
  //            Text("10mm - 20mm").foregroundStyle(.primary)
  //
  //          }
  //
  //          HStack(spacing: 5) {
  //
  //            Rectangle().fill(RainfallLevel.orange.color).frame(width: 20, height: 20)
  //
  //            Text("10mm - 20mm").foregroundStyle(.primary)
  //
  //          }
  //
  //          HStack(spacing: 5) {
  //
  //            Rectangle().fill(RainfallLevel.red.color).frame(width: 20, height: 20)
  //
  //            Text(" > 20mm").foregroundStyle(.primary)
  //
  //          }
  //        }
  //        Button {
  //
  //          viewModel.showMapLegend = false
  //
  //        } label: {
  //          Text("Dismiss")
  //            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
  //        }
  //
  //      }.padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
  //
  //    }
  //  }
}
