//
//  APIManager.swift
//  Hong Kong Bus ETA
//
//  Created by Ka Chun Wong on 21/1/2024.
//

import Alamofire
import Combine
import Foundation

protocol APIManagerType {
  static var shared: APIManagerType { get }
  var isReachable: CurrentValueSubject<Bool, Never> { get }
  func call(api: API) -> AnyPublisher<Data?, Error>
}

enum API {

  case rainfallNowcast

  case weatherWarning

  var url: URL {

    var urlString: String? = nil

    switch self {
    case .rainfallNowcast:
      urlString = "https://data.weather.gov.hk/weatherAPI/hko_data/F3/Gridded_rainfall_nowcast.csv"
    case .weatherWarning:
      urlString =
        "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warnsum&lang=en"
    }

    return URL(string: urlString!)!

  }

  var header: [HTTPHeader] {

    let dict: [String: String] =
      switch self {
      case .rainfallNowcast, .weatherWarning:
        [:]

      }

    return dict.map { (key: String, value: String) in
      HTTPHeader(name: key, value: value)
    }

  }

  var parameter: [String: String] {

    switch self {
    case .rainfallNowcast, .weatherWarning:
      return [:]

    }

  }

}

class APIManagerMock: APIManagerType {
  static var shared: APIManagerType = APIManagerMock()

  var isReachable: CurrentValueSubject<Bool, Never> = .init(true)

  func call(api: API) -> AnyPublisher<Data?, Error> {

    let fileName =
      switch api {
      case .rainfallNowcast:
        "mock_rainfall_data"
      case .weatherWarning:
        "mock_warning_data"
      }

    let fileExtension =
      switch api {
      case .rainfallNowcast:
        ".csv"
      case .weatherWarning:
        ".json"

      }

    if let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension),
      let data = try? Data(contentsOf: fileURL)
    {
      return Just(data).setFailureType(to: Error.self).eraseToAnyPublisher()

    }

    return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()

  }

}

class APIManager: APIManagerType {

  static var shared: APIManagerType = APIManager()

  var isReachable: CurrentValueSubject<Bool, Never> = CurrentValueSubject(true)

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

  func call(api: API) -> AnyPublisher<Data?, Error> {

    return Future { promise in

      Task {
        let request = AF.request(
          api.url, method: HTTPMethod(rawValue: self.getMethod(forAPI: api)),
          parameters: api.parameter, headers: HTTPHeaders(api.header))

        request.response { response in

          if let error = response.error {
            promise(.failure(error))
          } else {
            promise(.success(response.data))
          }

        }

      }

    }.eraseToAnyPublisher()

  }

  func getMethod(forAPI api: API) -> String {

    switch api {
    case .rainfallNowcast, .weatherWarning:
      return "GET"
    }
  }

}
