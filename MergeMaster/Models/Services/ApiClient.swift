//
//  ApiClient.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import RxSwift

enum ApiClientError: Error {
    case cannotCreateURL
    case cannotCreatePostData
    case cannotParse
}

private struct ResponseError: Decodable, Error, LocalizedError {
    let message: String?
    
    var errorDescription: String? {
        return message
    }
}

private enum Authorization {
    case token(Token)
    case stored
    case none
}

protocol ApiClientDelegate: AnyObject {
    func apiClientDidReceiveResponse(_ response: RequestManager.Response)
}

final class ApiClient {
    let configuration: Configuration
    let appState: AppState
    
    private let disposeBag = DisposeBag()
    private let requestManager = RequestManager(defaultHeaders: [:],
                                                isGZipEnabled: false)
    
    weak var delegate: ApiClientDelegate?
    
    init(configuration: Configuration, appState: AppState) {
        self.configuration = configuration
        self.appState = appState
    }
    
    func getProjects(token: Token?, search: String = "") -> Single<[Project]> {
        do {
            let request = try makeRequest(method: .get,
                                          path: "projects",
                                          params: ["membership": true,
                                                   "per_page": 1000,
                                                   "search": search])
            return performDecodable(request: request, authorization: token.map { .token($0) } ?? .stored)
        } catch {
            return .error(error)
        }
    }
    
    func getRequests(projectId: ProjectId) -> Single<[MergeRequest]> {
        do {
            let request = try makeRequest(method: .get,
                                          path: "projects/\(projectId)/merge_requests",
                                          params: ["state": "opened",
                                                   "with_merge_status_recheck": true])
            return performDecodable(request: request, authorization: .stored)
        } catch {
            return .error(error)
        }
    }
    
    func getApprovals(projectId: ProjectId, requestIid: Int) -> Single<Approvals> {
        do {
            let request = try makeRequest(
                method: .get,
                path: "projects/\(projectId)/merge_requests/\(requestIid)/approvals",
                params: nil
            )
            return performDecodable(request: request, authorization: .stored)
        } catch {
            return .error(error)
        }
    }
    
    //MARK: - private
    
    private func perform(request: Request, authorization: Authorization = .stored) -> Single<Data> {
        let request = addSecurityParameters(to: request, authorization: authorization)
        return self.requestManager.perform(request: request)
            .flatMap { [weak self] response -> Single<Data> in
                self?.delegate?.apiClientDidReceiveResponse(response)
                if response.isSuccess {
                    return Single.just(response.data)
                } else {
                    if let error = try? JSONDecoder().decode(ResponseError.self, from: response.data) {
                        return .error(error)
                    } else {
                        return .error(ApiClientError.cannotParse)
                    }
                }
            }
    }
    
    private func performDecodable<T: Decodable>(request: Request, authorization: Authorization) -> Single<T> {
        return perform(request: request, authorization: authorization)
            .decode()
    }
    
    private func addSecurityParameters(to request: Request,
                                       authorization: Authorization) -> Request {
        var params = request.params ?? [:]
        
        switch authorization {
        case .token(let token):
            params["private_token"] = token
        case .stored:
            params["private_token"] = appState.privateToken.value
        case .none:
            break
        }
        var request = request
        request.params = params
        return request
    }
    
    private func makeRequest(method: Request.Method, path: String, params: [String: Any]? = nil, headers: [String: Any]? = nil) throws -> Request {
        guard let url = configuration.apiURL else {
            throw ApiClientError.cannotCreateURL
        }
        return Request(baseURL: url,
                       path: path,
                       method: method,
                       params: params,
                       headers: headers)
    }
    
}

extension Single where Element == Data, Trait == SingleTrait {
    
    func decode<T: Decodable>() -> Single<T> {
        return map { try JSONDecoder().decode(T.self, from: $0) }
    }
    
}
