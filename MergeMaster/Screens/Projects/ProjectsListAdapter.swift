//
//  ProjectsListAdapter.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct ProjectsListAdapter: ViewAdapter {
  func adapt(state: ProjectsListReducer.State) -> ProjectsListView.State {
    let projects: [Project]
    switch state.selectedFilter {
    case .all:
      projects = state.projects
    case .selected:
      projects = state.selectedProjects
    }
    return ProjectsListView.State(
      items: projects.map { project in
        ProjectsListView.Item(
          id: project.id,
          title: project.name,
          header: project.namespace?.name,
          isSelected: state.selectedProjects.contains(where: { $0.id == project.id })
        )
      },
      numberOfSelectedProjects: state.selectedProjects.count, 
      filter: state.selectedFilter,
      searchTerm: state.searchTerm,
      isLoading: state.isLoading,
      error: state.error?.localizedDescription
    )
  }

  func adapt(action: ProjectsListView.Action) -> ProjectsListReducer.Action {
    .viewAction(action)
  }
}
