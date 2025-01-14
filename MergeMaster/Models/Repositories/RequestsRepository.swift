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
  var filters: [ProjectId: RequestsFilter] = [:]
  var response: IRequestsRepository.Requests = [:]
}

protocol IRequestsRepository {
  typealias Requests = [ProjectId: [MergeRequest]]
  typealias RequestsData = TimeBasedData<MergeRequestsFetchingData>
  var lastData: RequestsData? { get }
  var lastDataPublisher: AnyPublisher<RequestsData, Never> { get }
  func update(projectIds: [ProjectId], filters: [ProjectId: RequestsFilter]) async throws -> TimeBasedData<Requests>
  func clean()
}

final class RequestsRepository: IRequestsRepository {

  private enum StorageKeys: String {
    case requests = "stored_requests"
  }

  private let apiClient: ApiClient
  private let storage: ICodableStorage
  private let lastDataSubject: CurrentValueSubject<RequestsData?, Never>

  init(
    apiClient: ApiClient,
    storage: ICodableStorage
  ) {
    self.apiClient = apiClient
    self.storage = storage

    let storedData = storage.stored(type: RequestsData.self, key: StorageKeys.requests.rawValue)
    lastDataSubject = .init(storedData)
  }

  // MARK: - IRequestsRepository

  var lastData: RequestsData? {
    lastDataSubject.value
  }

  var lastDataPublisher: AnyPublisher<RequestsData, Never> {
    lastDataSubject
      .compactMap { $0 }
      .eraseToAnyPublisher()
  }

  @discardableResult
  func update(
    projectIds: [ProjectId],
    filters: [ProjectId: RequestsFilter]
  ) async throws -> TimeBasedData<Requests> {
    struct Pair {
      var projectId: ProjectId
      var requests: [MergeRequest]
    }
    let requests = try await withThrowingTaskGroup(of: Pair.self) { group in
      for projectId in projectIds {
        group.addTask {
          let requests: [MergeRequest]
          requests = try await self.mergeRequests(projectId: projectId)
          return Pair(projectId: projectId, requests: requests)
        }
      }
      var error: Error?
      var hasSuccessResult = false
      var result = Requests()
      while let projectResult = await group.nextResult() {
        switch projectResult {
        case .success(let success):
          hasSuccessResult = true
          result[success.projectId] = success.requests
        case .failure(let failure):
          error = failure
        }
      }
      if let error, hasSuccessResult == false {
        throw error
      } else {
        return result
      }
    }

    let fetchedDate = Date()
    let filteredRequests = filter(requests: requests, filters: filters)
    let data = MergeRequestsFetchingData(
      filters: filters,
      response: filteredRequests
    )
    let timeBasedData = TimeBasedData(time: fetchedDate, data: data)
    self.lastDataSubject.send(timeBasedData)
    let result = TimeBasedData(time: fetchedDate, data: filteredRequests)
    try? cache(timeBasedData)
    return result
  }

  func clean() {
    self.lastDataSubject.send(nil)
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
          self.check(request: request, orExpressions: filter.orExpressions)
        }
    }
    return requestsByProject
  }

  private func check(request: MergeRequest, orExpressions: [RequestsFilter.Expression]) -> Bool {
    orExpressions.contains { expression in
      expression.conditions.allSatisfy { condition in
        switch condition.property {
        case .assignee:
          return check(
            property: request.assignees.compactMap { $0.username },
            operator: condition.operator,
            value: condition.value
          )
        case .author:
          guard let username = request.author.username else { return false }
          return check(
            property: username,
            operator: condition.operator,
            value: condition.value
          )
        case .labels:
          return check(
            property: request.labels,
            operator: condition.operator,
            value: condition.value
          )
        case .reviewers:
          return check(
            property: request.reviewers.compactMap { $0.username },
            operator: condition.operator,
            value: condition.value
          )
        }
      }
    }
  }

  private func check(property: String, operator: RequestsFilter.Condition.Operator, value: String) -> Bool {
    switch `operator` {
    case .equal:
      return property == value
    case .notEqual:
      return property != value
    case .contains:
      assertionFailure("Unexpected behaviour")
      return false
    }
  }

  private func check(property: [String], operator: RequestsFilter.Condition.Operator, value: String) -> Bool {
    switch `operator` {
    case .equal:
      return property == [value]
    case .notEqual:
      return property != [value]
    case .contains:
      return property.contains(value)
    }
  }

  private func cache(_ data: RequestsData) throws {
    try storage.store(data, key: StorageKeys.requests.rawValue)
  }
}
