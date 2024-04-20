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

enum ErrorMessage {

  case none
  case networkError  // network unavailable
  case dataError  // failed to fetch data

  var message: String {

    switch self {
    case .none:
      ""
    case .networkError:
      "Failed to connect to the internet"
    case .dataError:
      "Failed to fetch weather data"
    }

  }
}

enum RainfallNowcastSummary {
  case none
  case noLocationAccess
  case noInfo
  case currentLocationNowcast(min: Double, max: Double)

  var rainfallNowcastMessage: String {

    switch self {
    case .none:
      return ""
    case .noLocationAccess:
      return "Location permission is required for current location rainfall nowcast."
    case .noInfo:
      return "Rainfall nowcast is not available for current location."
    case .currentLocationNowcast(let min, let max):
      return "Rainfall of your location in next 2 hours:\n\(min)mm - \(max)mm"
    }

  }

  var icon: Image {

    switch self {
    case .none:
      return Image(systemName: "ellipsis")
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

//protocol RainfallNowcastMapViewModelDelegate: AnyObject {

//}

class RainfallNowcastMapViewModel: NSObject, ObservableObject {

  let apiManager: APIManagerType

  var locationManager: CLLocationManagerType

  let mapCenter = CLLocationCoordinate2D(latitude: 22.345, longitude: 114.12)  // Victoria Harbour

  let HKSouthWestCoord = CLLocation(latitude: 22.15, longitude: 113.8)
  let HKNorthEastCoord = CLLocation(latitude: 22.58, longitude: 114.43)

  var mapBound: MapCameraBounds {
    .init(
      centerCoordinateBounds: .init(
        MKMapRect(
          origin: .init(
            CLLocationCoordinate2D(
              latitude: HKNorthEastCoord.coordinate.latitude,
              longitude: HKSouthWestCoord.coordinate.longitude)),
          size: .init(width: 320000, height: 320000))), minimumDistance: 10000,
      maximumDistance: 150000)
  }

  @Published
  var rainfallNowcastDataset: RainfallNowcastDataset? = nil

  @Published
  var weatherWarningDataset: WeatherWarningDataset? = nil

  @Published
  var datasetTimestampList: [Date] = []

  @Published
  var selectedTimestamp: Date? = nil

  @Published
  var autoplayTimer: Timer? = nil

  @Published
  var hasLocationPermission: Bool = false

  @Published
  var isFetchingRainfallNowcast: Bool = false

  @Published
  var currentLocation: CLLocation? = nil

  @Published
  var currentLocationRainfallRange: (Double, Double)?

  @Published
  var errorMessage: ErrorMessage = .networkError

  @Published
  var currentLocationRainfallRangeMessage: RainfallNowcastSummary = .none

  var cancellables: Set<AnyCancellable> = Set()

  var autoRefreshTimer: Timer?

  //  weak var delegate: RainfallNowcastMapViewModelDelegate?

  init(
    apiManager: APIManagerType = APIManager.shared,
    locationManager: CLLocationManagerType = CLLocationManager()
  ) {

    self.apiManager = apiManager
    self.locationManager = locationManager

    super.init()

    setupPublisher()

    self.locationManager.delegate = self

    self.locationManager.requestWhenInUseAuthorization()

    autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in

      guard let self else { return }

      self.refresh()

    }
  }

  func setupPublisher() {

    $currentLocationRainfallRange.combineLatest($hasLocationPermission, $rainfallNowcastDataset) {
      [weak self]
      currentLocationRainfallRange, hasLocationPermission, rainfallNowcastDataset
        -> RainfallNowcastSummary in

      guard let self else { return .none }

      if !isFetchingRainfallNowcast,
        rainfallNowcastDataset == nil
      {
        return .none
      }

      if !hasLocationPermission {

        return .noLocationAccess
      }

      guard let currentLocationRainfallRange else {
        return .noInfo
      }

      return .currentLocationNowcast(
        min: currentLocationRainfallRange.0, max: currentLocationRainfallRange.1)

    }.debounce(for: 0.3, scheduler: DispatchQueue.main).assign(
      to: &$currentLocationRainfallRangeMessage)

    $rainfallNowcastDataset.combineLatest($currentLocation) {
      [weak self]
      rainfallNowcastDataset, currentLocation -> (Double, Double)? in

      guard let self, let rainfallNowcastDataset, let currentLocation else { return nil }

      return rainfallNowcastDataset.getRainfallRangeForLocation(
        location: currentLocation.coordinate, southWestBoundary: HKSouthWestCoord.coordinate,
        northEastBoundary: HKNorthEastCoord.coordinate)
    }.assign(to: &$currentLocationRainfallRange)

    apiManager.isReachable.sink { [weak self] reachable in
      guard let self else { return }

      if reachable {
        self.refresh()
      }

      self.errorMessage = reachable ? .none : .networkError

    }.store(in: &cancellables)

  }

  func fetchRainfallNowcastData() {
    isFetchingRainfallNowcast = true

    autoplayTimer?.invalidate()
    autoplayTimer = nil

    apiManager.call(api: .rainfallNowcast).receive(on: DispatchQueue.main).sink {
      [weak self] result in

      self?.isFetchingRainfallNowcast = false

      switch result {
      case .failure(_):
        self?.rainfallNowcastDataset = nil
        self?.errorMessage = .dataError
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

  func fetchWeatherWarningDataset() {
    apiManager.call(api: .weatherWarning).receive(on: DispatchQueue.main).sink {
      [weak self] result in

      switch result {

      case .failure:
        self?.errorMessage = .dataError
        self?.weatherWarningDataset = nil
      default:
        break
      }

    } receiveValue: { [weak self] data in

      guard let self, let data else {
        self?.weatherWarningDataset = nil
        return
      }

      self.weatherWarningDataset = WeatherWarningDataset(data: data)

    }.store(in: &cancellables)
  }

  func refresh() {
    errorMessage = .none
    fetchRainfallNowcastData()
    fetchWeatherWarningDataset()
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
        withTimeInterval: 1, repeats: true,
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

  //    func onWeatherWarningRowClicked(){
  //        delegate?.rainfallNowcastMapViewModelDidRequestShowSummary(self)
  //    }

  //  func getWeatherWarningDescription(data: WeatherWarningDataset?) -> String? {
  //
  //    guard let firstWarning = data?.activeWarnings.first else {
  //      return nil
  //    }
  //
  //    var warning = (firstWarning.warningCodeDescription ?? " ") + firstWarning.description
  //
  //    if let warningCount = data?.activeWarnings.count, warningCount > 1 {
  //
  //      warning += " (and \(warningCount - 1) more)"
  //
  //    }
  //
  //    return warning
  //  }

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
