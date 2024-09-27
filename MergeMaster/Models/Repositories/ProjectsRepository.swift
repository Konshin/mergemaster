//
//  ProjectsRepository.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 25.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Combine

protocol IProjectsRepository {
  var lastProjects: [Project] { get }
  var lastProjectsPublisher: AnyPublisher<[Project], Never> { get }
  func projects(token: Token?, query: String?) async throws -> [Project]
}

extension IProjectsRepository {
  func projects(query: String? = nil) async throws -> [Project] {
    return try await projects(token: nil, query: query)
  }
}

final class ProjectsRepository {

  private enum StorageKeys: String {
    case projects = "stored_projects"
  }

  private let apiClient: ApiClient
  private let storage: ICodableStorage
  private let lastProjectsSubject: CurrentValueSubject<[Project], Never>

  init(
    apiClient: ApiClient,
    storage: ICodableStorage
  ) {
    self.apiClient = apiClient
    self.storage = storage

    let storedProjects = storage.stored(type: [Project].self, key: StorageKeys.projects.rawValue)
    lastProjectsSubject = .init(storedProjects ?? [])
  }
}

extension ProjectsRepository: IProjectsRepository {
  var lastProjects: [Project] {
    lastProjectsSubject.value
  }
  
  var lastProjectsPublisher: AnyPublisher<[Project], Never> {
    lastProjectsSubject.eraseToAnyPublisher()
  }
  
  func projects(
    token: Token?,
    query: String?
  ) async throws -> [Project] {
    let projects = try await apiClient.getProjects(
      token: token,
      search: query ?? ""
    )
    if query?.isEmpty != false {
      lastProjectsSubject.send(projects)
    }
    return projects
  }
}
