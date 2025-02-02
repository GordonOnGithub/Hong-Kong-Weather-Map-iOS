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

      if max > 0 {
        return "Your location's rainfall in next 2 hours: "
      } else {
        return "No rainfall is expected at your location in next 2 hours"
      }
    }

  }

  var rainfallRange: String? {

    switch self {
    case .currentLocationNowcast(let min, let max):
      if max > 0 {
        return "\(min)mm - \(max)mm"
      } else {
        return nil
      }
    default:
      return nil
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

  let HKSouthWestCoord = CLLocation(latitude: 22.15, longitude: 113.84)
  let HKNorthEastCoord = CLLocation(latitude: 22.564, longitude: 114.405)

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
  var regionalTemperatureDataset: RegionalTemperatureDataset? = nil

  @Published
  var selectedWeatherStation: String?

  @Published
  var datasetTimestampList: [Date] = []

  @Published
  var showRegionalTemperature: Bool = false

  @Published
  var selectedTimestamp: Date? = nil

  @Published
  var timestampSliderIndex: CGFloat = 0

  @Published
  var autoplayTimer: Timer? = nil

  @Published
  var isInBackground: Bool = false

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

  var lastRefreshTimestamp: Date?

  lazy var versionString: String = {

    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    return "v" + (appVersion ?? "")
  }()
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

    $timestampSliderIndex.map { [weak self] index -> Date? in

      guard let self, Int(index) < datasetTimestampList.count else { return nil }

      return datasetTimestampList[Int(index)]

    }.assign(to: &$selectedTimestamp)

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

  func fetchRegionalTemperatureDataset() {

    apiManager.call(api: .regionalTemperature).receive(on: DispatchQueue.main).sink {
      [weak self] result in

      switch result {

      case .failure:
        self?.errorMessage = .dataError
        self?.regionalTemperatureDataset = nil
      default:
        break
      }

    } receiveValue: { [weak self] data in

      guard let self, let data else {
        self?.regionalTemperatureDataset = nil
        return
      }

      self.regionalTemperatureDataset = RegionalTemperatureDataset(data: data)

    }.store(in: &cancellables)

  }

  func getTemperatureIconName(location: String) -> String {

    guard let temperatureString = regionalTemperatureDataset?.dataDict[location],
      let temperature = Double(temperatureString)
    else {
      return "thermometer.medium"
    }

    if temperature <= 15 {
      return "thermometer.low"
    } else if temperature >= 30 {
      return "thermometer.high"
    } else {
      return "thermometer.medium"
    }

  }

  func getWeatherStationTemperatureDescription(location: String) -> String {
    return "\(location)'s current temperature: "

  }

  func getWeatherStationTemperatureRange(location: String) -> String {

    let temperature = regionalTemperatureDataset?.dataDict[location] ?? " - "

    return "\(temperature)°C"

  }

  func refresh() {
    errorMessage = .none
    fetchRainfallNowcastData()
    fetchWeatherWarningDataset()
    fetchRegionalTemperatureDataset()
    lastRefreshTimestamp = Date()
  }

  func onEnterBackground() {

    isInBackground = true

  }

  func onEnterForeground() {

    isInBackground = false

    if let timestamp = lastRefreshTimestamp,
      Date().timeIntervalSince1970 - timestamp.timeIntervalSince1970 > 15
    {
      rainfallNowcastDataset = nil
      weatherWarningDataset = nil
      refresh()
    }
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
    } else if datasetTimestampList.count > 0 {

      selectedTimestamp = datasetTimestampList[0]

      timestampSliderIndex = 0.0

      self.autoplayTimer = Timer.scheduledTimer(
        withTimeInterval: 1.4, repeats: true,
        block: { [weak self] _ in

          guard let self, let selectedTimestamp else { return }

          for i in (0..<self.datasetTimestampList.count) {

            if selectedTimestamp == self.datasetTimestampList[i] {

              if i >= self.datasetTimestampList.count - 1 {

                self.autoplayTimer?.invalidate()
                self.autoplayTimer = nil

              } else {
                self.selectedTimestamp = self.datasetTimestampList[i + 1]
                self.timestampSliderIndex = CGFloat(i + 1)
              }
            }
          }
        })

    }

  }

  func handleMemoryWarning() {

    rainfallNowcastDataset = nil

    fetchRainfallNowcastData()
  }

  func onMapModeToggleClicked() {
    showRegionalTemperature.toggle()

    if showRegionalTemperature {

      guard let locations = regionalTemperatureDataset?.dataDict.keys, let currentLocation else {
        return
      }

      let sortedLocation = locations.sorted(by: { a, b in

        guard let aCoord = RegionalTemperatureDataset.getWeatherStationPosition(locationName: a)
        else {
          return false
        }

        guard let bCoord = RegionalTemperatureDataset.getWeatherStationPosition(locationName: b)
        else {
          return true
        }

        return currentLocation.distance(
          from: CLLocation(latitude: aCoord.latitude, longitude: aCoord.longitude))
          < currentLocation.distance(
            from: CLLocation(latitude: bCoord.latitude, longitude: bCoord.longitude))

      })

      selectedWeatherStation = sortedLocation.first

    } else {
      selectedWeatherStation = nil
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
