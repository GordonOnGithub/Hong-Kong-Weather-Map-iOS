//
//  RainfallNowcastMapViewModel.swift
//  Hong Kong Weather Map
//
//  Created by Ka Chun Wong on 24/3/2024.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI
import _MapKit_SwiftUI

enum RainfallNowcastSummary {
  case none
  case error
  case noLocationAccess
  case noInfo
  case currentLocationNowcast(min: Double, max: Double)

  var message: String {

    switch self {
    case .none:
      return ""
    case .error:
      return "Failed to obtain rainfall nowcast data. Please check network connection."
    case .noLocationAccess:
      return "Location permission is required for current location rainfall nowcast."
    case .noInfo:
      return "Rainfall nowcast is not available for current location."
    case .currentLocationNowcast(let min, let max):
      return "Rainfall nowcast of current location in the next 2 hours: \(min)mm - \(max)mm."
    }

  }

  var color: Color {
    switch self {
    case .error:
      return .yellow
    default:
      return .clear
    }
  }

  var icon: Image {

    switch self {
    case .none:
      return Image(systemName: "ellipsis")
    case .error:
      return Image(systemName: "exclamationmark.circle")
    case .noLocationAccess:
      return Image(systemName: "location.slash.circle")
    case .noInfo:
      return Image(systemName: "info.circle")
    case .currentLocationNowcast(let min, let max):

      switch RainfallLevel.getRainfallLevel(rainfall: max) {

      case .none:
        return Image(systemName: "cloud")

      case .blue, .green:
        return Image(systemName: "cloud.rain")
      case .orange, .red, .yellow:
        return Image(systemName: "cloud.heavyrain")

      }
    }
  }
}

protocol RainfallNowcastMapViewModelDelegate: AnyObject {

  func rainfallNowcastMapViewModelDidRequestShowMapLegend(_ viewModel: RainfallNowcastMapViewModel)

}

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
          size: .init(width: 400000, height: 400000))), minimumDistance: 5000,
      maximumDistance: 160000)
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

  @Published
  var currentLocation: CLLocation? = nil

  @Published
  var currentLocationRainfallRange: (Double, Double)?

  @Published
  var currentLocationRainfallRangeMessage: RainfallNowcastSummary = .none

  var cancellables: Set<AnyCancellable> = Set()

  weak var delegate: RainfallNowcastMapViewModelDelegate?

  init(
    apiManager: APIManagerType = APIManagerMock.shared,
    locationManager: CLLocationManagerType = CLLocationManager()
  ) {

    self.apiManager = apiManager
    self.locationManager = locationManager

    super.init()

    setupPublisher()

    self.locationManager.delegate = self

    self.locationManager.requestWhenInUseAuthorization()

    fetchRainfallNowcastData()

  }

  func setupPublisher() {

    $currentLocationRainfallRange.combineLatest($hasLocationPermission, $rainfallNowcastDataset) {
      [weak self]
      currentLocationRainfallRange, hasLocationPermission, rainfallNowcastDataset
        -> RainfallNowcastSummary in

      guard let self else { return .none }

      if !isFetching,
        rainfallNowcastDataset == nil
      {
        return .error
      }

      if !hasLocationPermission {

        return .noLocationAccess
      }

      guard let currentLocationRainfallRange else {
        return .noInfo
      }

      return .currentLocationNowcast(
        min: currentLocationRainfallRange.0, max: currentLocationRainfallRange.1)

    }.assign(to: &$currentLocationRainfallRangeMessage)

    $rainfallNowcastDataset.combineLatest($currentLocation) {
      [weak self]
      rainfallNowcastDataset, currentLocation -> (Double, Double)? in

      guard let self, let rainfallNowcastDataset, let currentLocation else { return nil }

      return rainfallNowcastDataset.getRainfallRangeForLocation(
        location: currentLocation.coordinate, southWestBoundary: HKSouthWestCoord.coordinate,
        northEastBoundary: HKNorthEastCoord.coordinate)
    }.assign(to: &$currentLocationRainfallRange)

  }

  func fetchRainfallNowcastData() {
    isFetching = true

    autoplayTimer?.invalidate()
    autoplayTimer = nil

    apiManager.call(api: .rainfallNowcast).sink { [weak self] result in

      self?.isFetching = false

      switch result {
      case .failure(_):
        self?.rainfallNowcastDataset = nil
      default:
        break

      }

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

    let hour = "\(Calendar.current.component(.hour, from: date))".leftPadded(
      length: 2, character: "0")

    let minute = "\(Calendar.current.component(.minute, from: date))".leftPadded(
      length: 2, character: "0")

    return "\(hour):\(minute)"

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
  func onMapLegendButtonClicked() {
    delegate?.rainfallNowcastMapViewModelDidRequestShowMapLegend(self)
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
      currentLocation = nil
      currentLocationRainfallRange = nil
    }

  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    guard let currentLocation = locations.last else {
      self.currentLocation = nil
      return
    }
    self.currentLocation = currentLocation

  }

}
