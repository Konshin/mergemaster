//
//  AppFacade.swift
//  MergeMaster
//
//  Created by Aleksei Konshin on 06.05.2021.
//  Copyright © 2021 Konshin. All rights reserved.
//

import Foundation

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
