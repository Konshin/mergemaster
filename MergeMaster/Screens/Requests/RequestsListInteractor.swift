//
//  RequestsListInteractor.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 26.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

protocol IRequestsListInteractor {
  typealias RequestsData = DataBySource<TimeBasedData<[RequestsInfo]>>
  func requests(allowCache: Bool) -> AsyncThrowingStream<RequestsData, Error>
  func update(filter: RequestsFilter, for projectId: ProjectId)
}

final class RequestsListInteractor {
  let filtersRepository: IFiltersRepository
  let savedProjectsRepository: ISavedProjectsRepository
  let requestsRepository: IRequestsRepository

  init(
    filtersRepository: IFiltersRepository,
    savedProjectsRepository: ISavedProjectsRepository,
    requestsRepository: IRequestsRepository
  ) {
    self.filtersRepository = filtersRepository
    self.savedProjectsRepository = savedProjectsRepository
    self.requestsRepository = requestsRepository
  }
}

extension RequestsListInteractor: IRequestsListInteractor {
  func requests(allowCache: Bool) -> AsyncThrowingStream<RequestsData, Error> {
    let projects = savedProjectsRepository.savedProjects
    let filters = filtersRepository.savedFilters
    return AsyncThrowingStream(RequestsData.self) { continuation in
      Task {
        if allowCache, let lastData = requestsRepository.lastData, lastData.data.filters == filters {
          let info = requestsInfo(requests: lastData.data.response, projects: projects)
          continuation.yield(.cached(TimeBasedData(time: lastData.time, data: info)))
        }

        do {
          let requests = try await requestsRepository.update(
            projectIds: projects.map { $0.id },
            filters: filters
          )
          continuation.yield(
            .fetched(
              requests
                .map {
                  requestsInfo(requests: $0, projects: projects)
                }
            )
          )
          continuation.finish()
        } catch {
          continuation.finish(throwing: error)
        }
      }
    }
  }

  func update(filter: RequestsFilter, for projectId: ProjectId) {
    var filters = filtersRepository.savedFilters
    filters[projectId] = filter
    filtersRepository.update(filters: filters)
  }

  // MARK: - Private

  private func requestsInfo(
    requests: IRequestsRepository.Requests,
    projects: [Project]
  ) -> [RequestsInfo] {
    projects.map { project in
      RequestsInfo(
        project: project,
        requests: requests[project.id] ?? []
      )
    }
  }
}

