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

  func projects(token: Token? = nil, search: String = "", forceRefresh: Bool = false) async throws -> [Project] {
    if search.isEmpty, !forceRefresh, let cached = cachedProjects {
      return cached
    } else {
      let projects = try await apiClient.getProjects(token: token, search: search)
      if search.isEmpty {
        cachedProjects = projects
      }
      return projects
    }
  }
    
    func mergeRequests(projectId: Int) async throws -> [MergeRequest] {
        try await apiClient.getRequests(projectId: projectId)
    }
    
    func approvalsInfo(projectId: Int, requestIid: Int) async throws -> Approvals {
        try await apiClient.getApprovals(
          projectId: projectId,
          requestIid: requestIid
        )
    }
    
  func requestsInfo() async throws -> [ProjectRequests] {
    let selectedProjects = appState.selectedProjects.value

    struct Pair {
      var projectId: ProjectId
      var requests: [MergeRequestInfo]
    }
    let requestsMap = await withTaskGroup(of: Pair.self) { group in
      for project in selectedProjects {
        group.addTask {
          let requests: [MergeRequest]
          do {
            requests = try await self.mergeRequests(projectId: project.id)
          } catch {
            requests = []
          }
          let info = requests.map { request in
            MergeRequestInfo(
              id: request.id,
              title: request.title,
              author: request.author,
              assignees: request.assignees,
              webURL: request.webUrl,
              numberOfComments: request.numberOfComments,
              approvedBy: []
            )
          }
          return Pair(projectId: project.id, requests: info)
        }
      }
      return await group.reduce(into: [ProjectId: [MergeRequestInfo]]()) { partialResult, pair in
        partialResult[pair.projectId] = pair.requests
      }
    }
    var numberOfRequests = 0
    let requests: [ProjectRequests] = selectedProjects.map { (project: Project) -> ProjectRequests in
      let requests = requestsMap[project.id] ?? []
      numberOfRequests += requests.count
      return ProjectRequests(
        project: project,
        requests: requests
      )
    }
    appState.numberOfRequests.accept(numberOfRequests)
    return requests
  }

}

// MARK: - Authorization
extension AppFacade {

  func authorize(
    gitlabUrlString: String,
    token: String
  ) async throws {
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
    } else {
      throw Error.invalidURL
    }
    // try to get projects
    _ = try await apiClient.getProjects(token: token)
    configuration.saveToCache()
    appState.privateToken.accept(token)
  }

  func logout() {
    cachedProjects?.removeAll()
    appState.privateToken.accept(nil)
    appState.selectedProjects.accept([])
    appState.numberOfRequests.accept(0)
  }

}
