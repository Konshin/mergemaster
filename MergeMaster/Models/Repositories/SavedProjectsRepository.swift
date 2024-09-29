//
//  SavedProjectsRepository.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 26.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

protocol ISavedProjectsRepository {
  var savedProjects: [Project] { get }
  func savedProject(id: ProjectId) -> Project?
  func update(savedProjects: [Project])
}

final class SavedProjectsRepository {
  private enum CodingKeys: String {
    case selectedProjects = "SELECTED_PROJECTS"
  }

  private var projects: [Project]
  private let store: ICodableStorage

  init(store: ICodableStorage) {
    self.store = store

    let saved = store.stored(type: [Project].self, key: CodingKeys.selectedProjects.rawValue)
    self.projects = saved ?? []
  }
}

extension SavedProjectsRepository: ISavedProjectsRepository {
  var savedProjects: [Project] { projects }

  func update(savedProjects: [Project]) {
    self.projects = savedProjects
  }

  func savedProject(id: ProjectId) -> Project? {
    projects.first(where: { $0.id == id })
  }
}
