//
//  RainfallNowcastMapViewModel.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 24/3/2024.
//

import Combine
import CoreLocation
import Foundation
import _MapKit_SwiftUI

class RainfallNowcastMapViewModel: NSObject, ObservableObject {

  let apiManager: APIManagerType

  var locationManager: CLLocationManagerType

  let mapCenter = CLLocationCoordinate2D(latitude: 22.3067953, longitude: 114.162375)  // Victoria Harbour

  let HKSouthWestCoord = CLLocation(latitude: 22.15, longitude: 113.8)
  let HKNorthEastCoord = CLLocation(latitude: 22.58, longitude: 114.45)

  var mapBound: MapCameraBounds {
    .init(
      centerCoordinateBounds: .init(
        MKMapRect(
          origin: .init(
            CLLocationCoordinate2D(
              latitude: HKNorthEastCoord.coordinate.latitude,
              longitude: HKSouthWestCoord.coordinate.longitude)),
          size: .init(width: 400000, height: 400000))), minimumDistance: 1000,
      maximumDistance: 200000)
  }

  @Published
  var rainfallNowcastDataset: RainfallNowcastDataset? = nil

  @Published
  var datasetTimestampList: [Date] = []

  @Published
  var selectedTimestamp: Date? = nil

  @Published
  var autoplayTimer: Timer? = nil

  @Published
  var hasLocationPermission: Bool = false

  @Published
  var isFetching: Bool = false

  var cancellables: Set<AnyCancellable> = Set()

  init(
    apiManager: APIManagerType = APIManagerMock.shared,
    locationManager: CLLocationManagerType = CLLocationManager()
  ) {

    self.apiManager = apiManager
    self.locationManager = locationManager

    super.init()

    self.locationManager.delegate = self

    self.locationManager.requestWhenInUseAuthorization()

    fetchRainfallNowcastData()
  }

  func fetchRainfallNowcastData() {
    isFetching = true

    autoplayTimer?.invalidate()
    autoplayTimer = nil

    apiManager.call(api: .rainfallNowcast).sink { [weak self] _ in

      self?.isFetching = false

    } receiveValue: { [weak self] data in
      guard let self, let data, let dataset = RainfallNowcastDataset(data: data) else {

        self?.rainfallNowcastDataset = nil

        return
      }

      self.rainfallNowcastDataset = dataset

      self.datasetTimestampList = dataset.sortedDatasetDict.keys.map({ date in
        date
      }).sorted(by: { a, b in
        a.timeIntervalSince1970 < b.timeIntervalSince1970
      })

      self.selectedTimestamp = datasetTimestampList.first

    }.store(in: &cancellables)

  }

  func isWithinHKBoundary(coord: CLLocationCoordinate2D) -> Bool {

    if coord.latitude > HKNorthEastCoord.coordinate.latitude {
      return false
    }

    if coord.latitude < HKSouthWestCoord.coordinate.latitude {
      return false
    }

    if coord.longitude > HKNorthEastCoord.coordinate.longitude {
      return false
    }

    if coord.longitude < HKSouthWestCoord.coordinate.longitude {
      return false
    }

    return true
  }

  func getTimeOfTheDay(_ date: Date) -> String {

    return
      "\(Calendar.current.component(.hour, from: date) ):\(Calendar.current.component(.minute, from: date))"

  }

  func onPlayButtonClicked() {

    if let autoplayTimer {
      autoplayTimer.invalidate()
      self.autoplayTimer = nil
    } else {

      self.autoplayTimer = Timer.scheduledTimer(
        withTimeInterval: 1.5, repeats: true,
        block: { [weak self] _ in

          guard let self, let selectedTimestamp else { return }

          for i in (0..<self.datasetTimestampList.count) {

            if selectedTimestamp == self.datasetTimestampList[i] {

              if i >= self.datasetTimestampList.count - 1 {
                self.selectedTimestamp = self.datasetTimestampList[0]
              } else {
                self.selectedTimestamp = self.datasetTimestampList[i + 1]
              }
            }
          }
        })

    }

  }

}

extension RainfallNowcastMapViewModel: CLLocationManagerDelegate {
  func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {

    switch status {

    case .authorizedAlways, .authorizedWhenInUse, .authorized:
      hasLocationPermission = true
      locationManager.startUpdatingLocation()

    default:
      hasLocationPermission = false
    }

  }

}
