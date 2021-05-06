//
//  RequestManager.swift
//  wheel-size-ios
//
//  Created by lustenko on 14/03/2020.
//  Copyright © 2020 Wheel-Size. All rights reserved.
//

import RxSwift

struct Request {
    
    enum Method: String {
        case get = "GET"
        case put = "PUT"
        case post = "POST"
    }
    
    var baseURL: URL
    var path: String
    var method: Method
    var params: [String: Any]?
    var headers: [String: Any]?
    
    func url() -> URL {
        var url = baseURL
        path
            .split(separator: "/")
            .filter { !$0.isEmpty }
            .forEach { url.appendPathComponent(String($0)) }
        url.appendPathComponent("")
        
        if case .get = method, let params = params, !params.isEmpty, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.queryItems = params.map { param in
                URLQueryItem(name: param.key, value: "\(param.value)")
            }
            url = components.url ?? url
        }
        
        return url
    }
    
    mutating func modifyHeaders(_ headers: [String: Any], replaceOnMerge: Bool) {
        self.headers = headers.merging(self.headers ?? [:]) { replaceOnMerge ? $0 : $1 }
    }
    
}

final class RequestManager: NSObject {
    
    typealias HTTPHeaders = [String: Any]
    
    struct Response {
        let data: Data
        let statusCode: Int
        
        var isSuccess: Bool {
            return 200...299 ~= statusCode
        }
    }

    // MARK: - Properties

    private let queue = DispatchQueue(label: "com.wheelsize.network")
    
    private let isGZipEnabled: Bool

    /// Стандартные хедеры для всех запросов
    private var defaultHeaders: HTTPHeaders
    
    private lazy var session: URLSession = {
        return URLSession.shared
    }()
    
    // MARK: - Construction

    init(defaultHeaders: HTTPHeaders, isGZipEnabled: Bool) {
        self.defaultHeaders = defaultHeaders
        self.isGZipEnabled = isGZipEnabled
        
        super.init()
        
        if isGZipEnabled {
            setGZipEnabled()
        }
    }

    // MARK: - Functions
    
    func perform(request: Request) -> Single<Response> {
        let defaultHeaders = self.defaultHeaders
        return Single.create { event in
            var request = request
            request.modifyHeaders(defaultHeaders, replaceOnMerge: false)
            
            let url = request.url()
            var urlRequest = URLRequest(url: url)
            request.headers?.forEach { pair in
                urlRequest.setValue("\(pair.value)", forHTTPHeaderField: pair.key)
            }
            let task = self.session.dataTask(with: urlRequest) { (data, response, error) in
                let httpResponse = response as? HTTPURLResponse
                self.logResponse(httpResponse, data: data, request: request)
                
                if let error = error {
                    event(.error(error))
                } else if let data = data {
                    let response = Response(data: data, statusCode: httpResponse?.statusCode ?? 0)
                    event(.success(response))
                } else {
                    event(.error(Error.unknown(statusCode: httpResponse?.statusCode ?? 0, data: data)))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
    
    // MARK: - private functions
    
    private func setGZipEnabled() {
        defaultHeaders["Accept-Encoding"] = "gzip, deflate, br";
        defaultHeaders["Content-Encoding"] = "gzip, deflate, br";
    }
    
    private func logResponse(_ response: HTTPURLResponse?, data: Data?, request: Request) {
        let description = requestDescription("REQUEST RESPONSE",
                                             request: request,
                                             response: response,
                                             data: data)
        print(description)
    }

    private func prettyString(from data: Data) -> String? {
        let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
        return object.flatMap(prettyString)
    }

    private func prettyString(from jsonObject: Any) -> String? {
        let data = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }

    private func requestDescription(_ title: String,
                                    request: Request,
                                    response: HTTPURLResponse?,
                                    data: Data?) -> String {
        let params = request.params
        let headers = request.headers ?? [:]
        var text = """
        ---- [ \(title) BEGIN ] ----
        - URL & METHOD: [\(request.method.rawValue)] \(request.url().absoluteString)
        """

        if !headers.isEmpty {
            text += "\n- HEADERS: \(prettyString(from: headers) ?? "")"
        }
        if params?.isEmpty == false {
            text += "\n- PARAMS: \(params.flatMap(prettyString) ?? "")"
        }

        if let response = response {
            let responseBody = data.flatMap(prettyString) ?? ""

            text += """
            \n- STATUS CODE: \(response.statusCode)
            - RESPONSE: \n\(responseBody)\n
            """
        }
        text += """
        ---- [ \(title) END ] ----
        """
        return text
    }

}

// MARK: - URLSessionDelegate
extension RequestManager: URLSessionDelegate {
    
}

// MARK: - Nested types
extension RequestManager {

    /// Ошибки менеджера
    ///
    /// - unknown: Неизвестная
    enum Error: Swift.Error, LocalizedError {
        case unknown(statusCode: Int, data: Data?)
        case cancelled
        
        var errorDescription: String? {
            switch self {
            case .unknown(let code, let data?):
                guard let string = String(data: data, encoding: .utf8) else {
                    return "Unknown"
                }
                return "\(code): \(string)"
            default:
                return "Unknown"
            }
        }
        
        var errorCode: Int {
            switch self {
            case .unknown(let code, _):
                return code
            case .cancelled:
                return 499
            }
            
        }
        
    }

}
