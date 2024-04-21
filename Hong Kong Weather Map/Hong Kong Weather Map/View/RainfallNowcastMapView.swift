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

    VStack {

      if viewModel.errorMessage != .none {

        HStack {
          Spacer()

          Image(systemName: "exclamationmark.circle").foregroundStyle(.black)

          Text(viewModel.errorMessage.message).foregroundStyle(.black)
            .font(.headline)
            .bold()
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
          Spacer()
        }.background(.yellow)
      }

      if let weatherWarningDataset = viewModel.weatherWarningDataset,
        !weatherWarningDataset.activeWarnings.isEmpty
      {

        WeatherWarningView(
          viewModel: WeatherWarningViewModel(weatherWarningDataset: weatherWarningDataset)
        )
        .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10))

      }
      GeometryReader { reader in

        ScrollView {
          VStack {

            if !viewModel.isFetchingRainfallNowcast {

              Group {
                HStack {

                  viewModel.currentLocationRainfallRangeMessage.icon

                  Text(viewModel.currentLocationRainfallRangeMessage.rainfallNowcastMessage)
                    .multilineTextAlignment(
                      .leading)

                  Spacer()
                }.padding(
                  EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
                )
              }
              .background(.lightBlue)
            }
            Map(
              position: .constant(
                .camera(.init(centerCoordinate: viewModel.mapCenter, distance: 130000))),
              bounds: viewModel.mapBound, interactionModes: [.pan, .zoom]
            ) {

              if let rainfallNowcastDataset = viewModel.rainfallNowcastDataset,
                let selectedTimestamp = viewModel.selectedTimestamp,
                let datasetOfSelectedTimestamp = rainfallNowcastDataset.sortedDatasetDict[
                  selectedTimestamp]?.filter({ data in
                    data.rainfallLevel != nil
                      && viewModel.isWithinHKBoundary(coord: data.coordinate)
                  })
              {

                ForEach(datasetOfSelectedTimestamp) { data in
                  MapPolygon(coordinates: data.coordinate.coordinatesForDrawingSquare())
                    .foregroundStyle(data.rainfallLevel!.color.opacity(0.6))
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

          if !viewModel.isFetchingRainfallNowcast {

            HStack {

              Button(
                action: {
                  viewModel.refresh()
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
                .disabled(viewModel.isFetchingRainfallNowcast)

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
                  .disabled(viewModel.isFetchingRainfallNowcast)
              }
            }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))

            HStack {

              if viewModel.rainfallNowcastDataset != nil {

                Text(
                  "Last update: \(viewModel.rainfallNowcastDataset?.creationTimestamp.ISO8601Format(.iso8601(timeZone: TimeZone.current)) ?? "")"
                )
                .font(.system(size: 12))
              }
            }

            Group {
              VStack {

                HStack {
                  Text("Map Legend:").font(.headline)
                  Spacer()

                }

                HStack(spacing: 5) {

                  Rectangle().fill(RainfallLevel.blue.color).frame(width: 20, height: 20)

                  Text("0.5 - 2.5 mm").foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(width: 100)

                  Spacer()
                  Rectangle().fill(RainfallLevel.green.color).frame(width: 20, height: 20)

                  Text("2.5 - 5 mm").foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(width: 100)

                  Spacer()

                }

                HStack(spacing: 5) {

                  Rectangle().fill(RainfallLevel.yellow.color).frame(width: 20, height: 20)

                  Text("5 - 10 mm").foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(width: 100)
                  Spacer()
                  Rectangle().fill(RainfallLevel.orange.color).frame(width: 20, height: 20)

                  Text("10 - 20 mm").foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(width: 100)

                  Spacer()

                }

                HStack(spacing: 5) {
                  Rectangle().fill(RainfallLevel.red.color).frame(width: 20, height: 20)

                  Text(" > 20 mm").foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(width: 100)

                  Spacer()

                }
              }.padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            }
            .background(content: {
              RoundedRectangle(cornerRadius: 5)
                .fill(.lightYellow)
                .stroke(.primary, lineWidth: 1)
            })

            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
          }

          Spacer()
        }
      }
      Spacer()
    }
    .background(.white)
    .overlay {
      if viewModel.isFetchingRainfallNowcast {
        ZStack {
          Rectangle().fill(.black.opacity(0.3))
          ProgressView {
            Text("Loading...")
          }
        }
      }
    }
    .onAppear {
      UIPageControl.appearance().currentPageIndicatorTintColor = .black
      UIPageControl.appearance().pageIndicatorTintColor = .gray

    }
    .onReceive(
      NotificationCenter.default.publisher(
        for: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    ) { _ in

      viewModel.handleMemoryWarning()

    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    ) { _ in

      viewModel.onEnterForeground()

    }
  }

}
