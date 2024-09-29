//
//  ProjectsListAssembly.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import ComposableArchitecture

struct ProjectsListAssembly {
  let dependencies: Dependencies

  func makeView(router: Router<ProjectsListReducer.Route>) -> ProjectsListView {
    let reducer = ProjectsListReducer(
      router: router,
      projectsRepository: dependencies.projectsRepository,
      selectedProjectsRepository: dependencies.selectedProjectsRepository
    )
    let state = ProjectsListReducer.State(selectedProjects: dependencies.selectedProjectsRepository.savedProjects)
    return ProjectsListView(
      store: .adapted(state: state, reducer: { reducer }, adapter: ProjectsListAdapter())
    )
  }
}
