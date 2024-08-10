//
//  RequestsListReducer.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
struct RequestsListReducer {

  let router: Router<Route>
  let appFacade: AppFacade

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .viewAction(let action):
      return reduce(into: &state, viewAction: action)
    case .didLoad(let result):
      return handleLoadResult(result, state: &state)
    }
  }

  private func reduce(into state: inout State, viewAction: RequestsListView.Action) -> Effect<Action> {
    switch viewAction {
    case .appeared:
      return loadRequests(state: &state)
    case .reload:
      return loadRequests(state: &state)
    case .exit:
      router.syncTrigger(.exit)
    case .changeProjects:
      router.syncTrigger(.changeProjects)
    case .logout:
      router.syncTrigger(.logout)
    case .tapProject(let projectId):
      guard let project = state.projectRequests.first(where: { $0.project.id == projectId })?.project,
              let url = URL(string: project.webUrl) else { break }
      router.syncTrigger(.openProject(url))
    case .tapProjectSettings(let projectId):
//      router.syncTrigger(.settings(projectId: projectId))
      state.settingsOpenedForProjectId = projectId
    case .settingsWasClosed:
      state.settingsOpenedForProjectId = nil
    }
    return .none
  }

  // MARK: - Actions

  private func handleLoadResult(
    _ result: Result<[AppFacade.ProjectRequests], Error>, state: inout State
  ) -> Effect<Action> {
    state.isLoading = false
    switch result {
    case .success(let projects):
      state.projectRequests = projects
    case .failure(let failure):
      state.projectRequests = []
      state.error = failure
    }
    return .none
  }

  private func loadRequests(state: inout State) -> Effect<Action> {
    state.isLoading = true
    state.error = nil
    return .run { send in
      do {
        let requests = try await appFacade.requestsInfo()
        await send(.didLoad(requests: .success(requests)))
      } catch {
        guard !(error is CancellationError) else { return }
        await send(.didLoad(requests: .failure(error)))
      }
    }
    .cancellable(id: "load_requests", cancelInFlight: true)
  }
}

extension RequestsListReducer {
  enum Route {
    case settings(projectId: ProjectId)
    case changeProjects
    case logout
    case exit
    case openProject(URL)
  }

  struct State {
    var projectRequests: [AppFacade.ProjectRequests] = []
    var isLoading: Bool = false
    var error: Error?
    var settingsOpenedForProjectId: ProjectId?
  }

  enum Action {
    case viewAction(RequestsListView.Action)
    case didLoad(requests: Result<[AppFacade.ProjectRequests], Error>)
  }
}
