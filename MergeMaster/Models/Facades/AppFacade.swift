//
//  AppFacade.swift
//  MergeMaster
//
//  Created by Aleksei Konshin on 06.05.2021.
//  Copyright © 2021 Konshin. All rights reserved.
//

import Foundation
import RxSwift

final class AppFacade {
    
    private let apiClient: ApiClient
    private let appState: AppState
    private let configuration: Configuration
    
    private var cachedProjects: [Project]?
    
    init(apiClient: ApiClient,
         configuration: Configuration,
         appState: AppState) {
        self.apiClient = apiClient
        self.configuration = configuration
        self.appState = appState
        
        apiClient.delegate = self
    }
    
    // MARK: - private functions
    
}

// MARK: - ApiClientDelegate
extension AppFacade: ApiClientDelegate {
    
    func apiClientDidReceiveResponse(_ response: RequestManager.Response) {
        if response.statusCode == 401 {
            // force logout
            logout()
        }
    }
    
}

// MARK: - Structures
extension AppFacade {
    
    private enum Error: Swift.Error, LocalizedError {
        case invalidURL
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            }
        }
    }
    
}

// MARK: - Projects
extension AppFacade {
    
    struct ProjectRequests {
        let project: Project
        let requests: [MergeRequestInfo]
    }
    
    func projects(token: Token? = nil, forceRefresh: Bool = false) -> Single<[Project]> {
        if !forceRefresh, let cached = cachedProjects {
            return .just(cached)
        } else {
            return apiClient.getProjects(token: token)
                .do(onSuccess: { [weak self] projects in
                    self?.cachedProjects = projects
                })
        }
    }
    
    func mergeRequests(projectId: Int) -> Single<[MergeRequest]> {
        return apiClient.getRequests(projectId: projectId)
    }
    
    func approvalsInfo(projectId: Int, requestIid: Int) -> Single<Approvals> {
        return apiClient.getApprovals(projectId: projectId, requestIid: requestIid)
    }
    
    func requestsInfo() -> Single<[ProjectRequests]> {
        struct IntermediateData {
            let project: Project
            let requests: [MergeRequest]
        }
        
        return projects()
            .map { [appState] projects -> [Project] in
                let projectsByID = projects.reduce(into: [ProjectId: Project]()) { (result, project) in
                    result[project.id] = project
                }
                return appState.selectedProjects.value.compactMap { id in
                    return projectsByID[id]
                }
            }
            .flatMap { projects -> Single<[IntermediateData]> in
                let requests: [Single<IntermediateData>] = projects.map { project in
                    self.mergeRequests(projectId: project.id)
                        .catchErrorJustReturn([])
                        .map { requests in
                            IntermediateData(project: project,
                                             requests: requests)
                        }
                }
                return Single.zip(requests)
            }
            .flatMap { data -> Single<[ProjectRequests]> in
                let requests: [Single<ProjectRequests>] = data.map { data in
                    let mergeRequests: [Single<(MergeRequest, Approvals)>] = data.requests.map { request in
                        self.approvalsInfo(projectId: data.project.id,
                                           requestIid: request.iid)
                            .map { (request, $0) }
                    }
                    return Single.zip(mergeRequests) { requests in
                        let info = requests.map { (request, approvals) in
                            return MergeRequestInfo(
                                id: request.id,
                                title: request.title,
                                author: request.author,
                                webURL: request.webUrl,
                                numberOfComments: request.numberOfComments,
                                approvedBy: approvals.approvedBy.map { $0.user }
                            )
                        }
                        return ProjectRequests(
                            project: data.project,
                            requests: info
                        )
                    }
                }
                return Single.zip(requests)
            }
            .do(onSuccess: { [appState] info in
                let numberOfRequests = info.reduce(0) { $0 + $1.requests.count }
                appState.numberOfRequests.accept(numberOfRequests)
            })
    }
    
}

// MARK: - Authorization
extension AppFacade {
    
    func authorize(gitlabUrlString: String,
                   token: String) -> Single<Void> {
        
        let prepareURL = Single<Token>.create { [configuration] observer in
            var url: URL? {
                guard var components = URLComponents(string: gitlabUrlString) else { return nil }
                if !components.path.isEmpty && components.host == nil {
                    components.host = components.path
                    components.path = ""
                }
                if components.scheme == nil {
                    components.scheme = "https"
                }
                return components.url
            }
            if let gitlabURL = url {
                configuration.update(serverUrl: gitlabURL)
                observer(.success(token))
            } else {
                observer(.error(Error.invalidURL))
            }
            return Disposables.create()
        }
        return prepareURL
            .flatMap { [apiClient] token in
                apiClient.getProjects(token: token)
                    .map { _ in token }
            }
            .do(onSuccess: { [configuration, appState] token in
                configuration.saveToCache()
                appState.privateToken.accept(token)
            })
            .map { _ in Void() }
    }
    
    func logout() {
        cachedProjects?.removeAll()
        appState.privateToken.accept(nil)
        appState.selectedProjects.accept([])
        appState.numberOfRequests.accept(0)
    }
    
}
