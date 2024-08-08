//
//  ProjectsListAdapter.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct ProjectsListAdapter {
  func adapt(state: ProjectsListReducer.State) -> ProjectsListView.State {
    ProjectsListView.State(
      items: state.projects.map { project in
        ProjectsListView.Item(
          id: project.id,
          title: project.name,
          header: project.namespace?.name,
          isSelected: state.selectedProjects.contains(where: { $0.id == project.id })
        )
      },
      searchTerm: state.searchTerm,
      isLoading: state.isLoading,
      error: state.error?.localizedDescription
    )
  }

  func adapt(action: ProjectsListView.Action) -> ProjectsListReducer.Action {
    .viewAction(action)
  }
}
