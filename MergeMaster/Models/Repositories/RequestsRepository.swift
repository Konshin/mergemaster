//
//  RequestsRepository.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 31.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation
import Combine

struct MergeRequestsFetchingData: Codable {
  var filters: [ProjectId: RequestsFilter]
  var response: IRequestsRepository.Requests
}

protocol IRequestsRepository {
  typealias Requests = [ProjectId: [MergeRequest]]
  var lastData: MergeRequestsFetchingData { get }
  var lastDataPublisher: AnyPublisher<MergeRequestsFetchingData, Never> { get }
  func update(projectIds: [ProjectId], filters: [ProjectId: RequestsFilter]) async throws -> Requests
  func clean()
}

final class RequestsRepository: IRequestsRepository {

  private enum StorageKeys: String {
    case requests = "stored_requests"
  }

  private let apiClient: ApiClient
  private let storage: ICodableStorage
  private let lastDataSubject: CurrentValueSubject<MergeRequestsFetchingData, Never>

  init(
    apiClient: ApiClient,
    storage: ICodableStorage
  ) {
    self.apiClient = apiClient
    self.storage = storage

    let storedData = storage.stored(type: MergeRequestsFetchingData.self, key: StorageKeys.requests.rawValue)
    lastDataSubject = .init(storedData ?? .init(filters: [:], response: [:]))
  }

  // MARK: - IRequestsRepository

  var lastData: MergeRequestsFetchingData {
    lastDataSubject.value
  }

  var lastDataPublisher: AnyPublisher<MergeRequestsFetchingData, Never> {
    lastDataSubject.eraseToAnyPublisher()
  }

  @discardableResult
  func update(
    projectIds: [ProjectId],
    filters: [ProjectId: RequestsFilter]
  ) async throws -> Requests {
    struct Pair {
      var projectId: ProjectId
      var requests: [MergeRequest]
    }
    let requests = await withTaskGroup(of: Pair.self) { group in
      for projectId in projectIds {
        group.addTask {
          let requests: [MergeRequest]
          do {
            requests = try await self.mergeRequests(projectId: projectId)
          } catch {
            requests = []
          }
          return Pair(projectId: projectId, requests: requests)
        }
      }
      return await group.reduce(into: Requests()) { partialResult, pair in
        partialResult[pair.projectId] = pair.requests
      }
    }
    let filteredRequests = filter(requests: requests, filters: filters)
    let data = MergeRequestsFetchingData(
      filters: filters,
      response: filteredRequests
    )
    self.lastDataSubject.send(data)
    return filteredRequests
  }

  // MARK: - Private

  private func mergeRequests(projectId: Int) async throws -> [MergeRequest] {
      try await apiClient.getRequests(projectId: projectId)
  }

  private func filter(requests: Requests, filters: [ProjectId: RequestsFilter]) -> Requests {
    guard !filters.isEmpty else { return requests }
    var requestsByProject = requests
    for (projectId, requests) in requests {
      guard let filter = filters[projectId], !filter.isEmpty else { continue }
      requestsByProject[projectId] = requests
        .filter { request in
          filter.orExpressions.contains { expression in
            expression.conditions.allSatisfy { condition in
              switch condition.property {
              case .assignee:
                return request.assignees.contains(where: { $0.username == condition.value })
              case .author:
                return request.author.username == condition.value
              }
            }
          }
        }
    }
    return requestsByProject
  }

  func clean() {
    self.lastDataSubject.send(.init(filters: [:], response: [:]))
  }
}
