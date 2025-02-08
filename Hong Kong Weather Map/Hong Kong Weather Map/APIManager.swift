//
//  APIManager.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Alamofire
import Combine
import Foundation

protocol APIManagerType: AnyObject, Sendable {
  static var shared: APIManagerType { get }
  var isReachable: CurrentValueSubject<Bool, Never> { get }

  func call(api: API) async throws -> Data?
}

enum API {

  case rainfallNowcast

  case weatherWarning

  case regionalTemperature

  var url: URL {

    var urlString: String? = nil

    switch self {
    case .rainfallNowcast:
      urlString = "https://data.weather.gov.hk/weatherAPI/hko_data/F3/Gridded_rainfall_nowcast.csv"
    case .weatherWarning:
      urlString =
        "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warnsum&lang=en"
    case .regionalTemperature:
      urlString =
        "https://data.weather.gov.hk/weatherAPI/hko_data/regional-weather/latest_1min_temperature.csv"
    }

    return URL(string: urlString!)!

  }

  var header: [HTTPHeader] {

    let dict: [String: String] =
      switch self {
      case .rainfallNowcast, .weatherWarning, .regionalTemperature:
        [:]

      }

    return dict.map { (key: String, value: String) in
      HTTPHeader(name: key, value: value)
    }

  }

  var parameter: [String: String] {

    switch self {
    case .rainfallNowcast, .weatherWarning, .regionalTemperature:
      return [:]

    }

  }

}

class APIManagerMock: APIManagerType, @unchecked Sendable {
  static let shared: APIManagerType = APIManagerMock()

  var isReachable: CurrentValueSubject<Bool, Never> = .init(true)

  func call(api: API) async throws -> Data? {

    let fileName =
      switch api {
      case .rainfallNowcast:
        "mock_rainfall_data"
      case .weatherWarning:
        "mock_warning_data"
      case .regionalTemperature:
        "mock_temperature_data"
      }

    let fileExtension =
      switch api {
      case .rainfallNowcast, .regionalTemperature:
        ".csv"
      case .weatherWarning:
        ".json"

      }

    if let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension),
      let data = try? Data(contentsOf: fileURL)
    {
      return data

    }

    return nil

  }

}

class APIManager: APIManagerType, @unchecked Sendable {

  static let shared: APIManagerType = APIManager()

  private(set) var isReachable: CurrentValueSubject<Bool, Never> = CurrentValueSubject(true)

  private init() {
    NetworkReachabilityManager.default?.startListening(
      onQueue: .main,
      onUpdatePerforming: { status in

        switch status {
        case .reachable:
          self.isReachable.value = true
        default:
          self.isReachable.value = false
        }

      })
  }

  func call(api: API) async throws -> Data? {

    let request = AF.request(
      api.url, method: HTTPMethod(rawValue: self.getMethod(forAPI: api)),
      parameters: api.parameter, headers: HTTPHeaders(api.header))

    let response = await request.serializingData().response

    if let error = response.error {
      throw error
    }

    if let data = response.data, response.error == nil {
      return data
    }

    return nil

  }

  func getMethod(forAPI api: API) -> String {

    switch api {
    case .rainfallNowcast, .weatherWarning, .regionalTemperature:
      return "GET"
    }
  }

}
