//
//  ProjectsListReducer.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 06.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ProjectsListReducer {

  let router: Router<Route>
  let appFacade: AppFacade
  let appState: AppState

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .viewAction(let action):
      return reduce(into: &state, viewAction: action)
    case .didLoad(let result):
      return handleLoadResult(result, state: &state)
    }
  }

  private func reduce(into state: inout State, viewAction: ProjectsListView.Action) -> Effect<Action> {
    switch viewAction {
    case .appeared:
      return loadProjects(state: &state)
    case .update(let searchTerm):
      state.searchTerm = searchTerm
      return loadProjects(state: &state)
    case .setSelected(let id, let selected):
      if selected {
        guard let project = state.projects.first(where: { $0.id == id }) else { break }
        state.selectedProjects.append(project)
      } else {
        state.selectedProjects.removeAll(where: { $0.id == id })
      }
      appState.selectedProjects.accept(state.selectedProjects)
    case .confirm:
      router.syncTrigger(.confirm)
    case .reload:
      return loadProjects(state: &state)
    case .changeFilter(let filter):
      state.selectedFilter = filter
    }
    return .none
  }

  // MARK: - Actions

  private func handleLoadResult(_ result: Result<[Project], Error>, state: inout State) -> Effect<Action> {
    state.isLoading = false
    switch result {
    case .success(let projects):
      state.projects = projects
    case .failure(let failure):
      state.error = failure
    }
    return .none
  }

  private func loadProjects(state: inout State) -> Effect<Action> {
    state.isLoading = true
    state.error = nil
    let searchTerm = state.searchTerm
    return .run { send in
      do {
        let projects = try await appFacade.projects(search: searchTerm)
        await send(.didLoad(projects: .success(projects)))
      } catch {
        guard !(error is CancellationError) else { return }
        await send(.didLoad(projects: .failure(error)))
      }
    }
    .cancellable(id: "load_projects", cancelInFlight: true)
  }
}

extension ProjectsListReducer {
  enum Route {
    case confirm
  }

  struct State {
    var projects: [Project] = []
    var selectedProjects: [Project] = []
    var searchTerm: String = ""
    var isLoading: Bool = false
    var error: Error?
    var selectedFilter: ProjectsListView.ProjectsFilter = .all
  }

  enum Action {
    case viewAction(ProjectsListView.Action)
    case didLoad(projects: Result<[Project], Error>)
  }
}
