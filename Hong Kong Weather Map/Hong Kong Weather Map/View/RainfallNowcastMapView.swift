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
        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))

      }

      if !viewModel.isFetchingRainfallNowcast {
        summaryRow
      }

      Map(
        position: .constant(
          .camera(.init(centerCoordinate: viewModel.mapCenter, distance: 180000))),
        bounds: viewModel.mapBound, interactionModes: [.pan, .zoom],
        selection: $viewModel.selectedWeatherStation

      ) {

        if viewModel.showRegionalTemperature {
          if let regionalTemperatureDataset = viewModel.regionalTemperatureDataset {

            ForEach(regionalTemperatureDataset.dataDict.sorted(by: >), id: \.key) {
              location, temperature in

              if let coord = RegionalTemperatureDataset.getWeatherStationPosition(
                locationName: location)
              {

                Marker(coordinate: coord) {
                  Text("\(location)\n\(temperature)°C")
                }.tag(location as String?)

              }
            }
          }
        } else {

          if let selectedTimestamp = viewModel.selectedTimestamp,
            let rainfallNowcastDataset = viewModel.rainfallNowcastDataset,
            let mergedGridOfSelectedTimestamp = rainfallNowcastDataset.sortedMergedGridDict[
              selectedTimestamp]
          {
            ForEach(mergedGridOfSelectedTimestamp) { data in
              MapPolygon(coordinates: data.coordinates)
                .foregroundStyle(data.rainfallLevel.color.opacity(0.5))
            }
          }

          MapPolygon(coordinates: [
            CLLocation.HKNorthEastCoord.coordinate,

            CLLocationCoordinate2D(
              latitude: CLLocation.HKSouthWestCoord.coordinate.latitude,
              longitude: CLLocation.HKNorthEastCoord.coordinate.longitude),

            CLLocation.HKSouthWestCoord.coordinate,

            CLLocationCoordinate2D(
              latitude: CLLocation.HKNorthEastCoord.coordinate.latitude,
              longitude: CLLocation.HKSouthWestCoord.coordinate.longitude),

          ]).stroke(.black, lineWidth: 1)
            .foregroundStyle(.clear)

        }

        UserAnnotation()

      }.mapControls {
        if viewModel.hasLocationPermission {
          MapUserLocationButton()
        }
      }
      .mapStyle(
        .standard(elevation: .flat, pointsOfInterest: .excludingAll, showsTraffic: true)
      )
      .frame(height: 300)

      if !viewModel.isFetchingRainfallNowcast {

        if !viewModel.showRegionalTemperature {
          rainfallNowCastButtonsPanelView
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10))
        }

        Button {
          viewModel.showLegend = true
        } label: {
          Label("Show Legend", systemImage: "info.circle")
        }.padding(10)

        Spacer()

        HStack {

          if viewModel.rainfallNowcastDataset != nil {

            Text(
              "Last update: \(viewModel.rainfallNowcastDataset?.creationTimestamp.ISO8601Format(.iso8601(timeZone: TimeZone.current)) ?? "")"
            )
            .font(.system(size: 12))
          }
        }

        Text(viewModel.versionString).font(.system(size: 10))
      }

    }
    .background(.white)
    .overlay {
      if viewModel.fetchRainfallNowcastTask != nil {
        ZStack {
          Rectangle().fill(.black.opacity(0.3))
          ProgressView {
            Text("Loading...")
          }
        }.ignoresSafeArea(.all)
      } else if viewModel.showLegend {
        ZStack {
          Rectangle().fill(.black.opacity(0.3))
          mapLegend
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)).clipShape(
              RoundedRectangle(cornerRadius: 5)
            )
            .onTapGesture {
              viewModel.showLegend = false
            }
        }.ignoresSafeArea(.all)

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
      NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
    ) { _ in

      viewModel.onEnterBackground()

    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    ) { _ in

      viewModel.onEnterForeground()

    }
  }

  var summaryRow: some View {
    Group {
      HStack {

        if viewModel.selectedWeatherStation == nil {
          viewModel.currentLocationRainfallRangeMessage.icon
            .frame(width: 20)

          Text(viewModel.currentLocationRainfallRangeMessage.rainfallNowcastMessage)
            + Text(viewModel.currentLocationRainfallRangeMessage.rainfallRange ?? "").font(
              .system(size: 18, weight: .medium))
        } else {

          Image(
            systemName: viewModel.getTemperatureIconName(
              location: viewModel.selectedWeatherStation ?? "")
          )
          .frame(width: 20)

          Text(
            viewModel.getWeatherStationTemperatureDescription(
              location: viewModel.selectedWeatherStation ?? ""))
            + Text(
              viewModel.getWeatherStationTemperatureRange(
                location: viewModel.selectedWeatherStation ?? "")
            ).font(.system(size: 18, weight: .medium))

        }

        Spacer()

        Button(
          action: {
            viewModel.refresh()
          },
          label: {
            Image(systemName: "arrow.clockwise")
              .frame(width: 30, height: 30)
              .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))

          }
        ).foregroundStyle(.white)
          .background(.green)
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .disabled(viewModel.fetchRainfallNowcastTask != nil)
          .shadow(radius: 3, x: 0, y: 3)
        Button(
          action: {
            viewModel.onMapModeToggleClicked()
          },
          label: {
            Image(
              systemName: viewModel.showRegionalTemperature
                ? "cloud.rain" : "thermometer.medium"
            )
            .frame(width: 30, height: 30)
            .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
          }
        ).foregroundStyle(.white)
          .background(
            viewModel.autoplayTask != nil
              ? .gray : (viewModel.showRegionalTemperature ? .blue : .orange)
          )
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .disabled(viewModel.isFetchingRainfallNowcast || viewModel.autoplayTask != nil)
          .shadow(radius: 3, x: 0, y: 3)

      }.padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
    }.background(.lightBlue)

  }

  var rainfallNowCastButtonsPanelView: some View {
    HStack {

      if !viewModel.datasetTimestampList.isEmpty,
        let selectedTimestamp = viewModel.selectedTimestamp
      {
        if let date = viewModel.selectedTimestamp {
          Text(viewModel.getTimeOfTheDay(date)).font(.headline)
        }

        Slider(
          value: $viewModel.timestampSliderIndex,
          in: 0.0...CGFloat(viewModel.datasetTimestampList.count - 1), step: 1.0
        )
        .disabled(viewModel.autoplayTask != nil).padding(5)

        Button(
          action: {

            viewModel.onPlayButtonClicked()

          },
          label: {
            HStack {

              if viewModel.autoplayTask == nil {
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
          .background(viewModel.autoplayTask == nil ? .green : .red)
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .disabled(viewModel.isFetchingRainfallNowcast)
          .shadow(radius: 3, x: 0, y: 3)

      }
    }
  }

  var mapLegend: some View {
    Group {
      VStack {

        HStack {
          Text("Map Legend:").font(.headline)
          Spacer()

          Image(systemName: "xmark").foregroundStyle(.black)

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

          Image(systemName: "mappin.circle.fill")
            .foregroundColor(.red)
            .frame(width: 20, height: 20)
          Text("Weather Station").foregroundStyle(.primary).font(.system(size: 12))
            .frame(width: 100)

          Spacer()

        }
      }.padding(20)
    }
    .background(content: {
      RoundedRectangle(cornerRadius: 5)
        .fill(.lightYellow)
    })
  }

}
