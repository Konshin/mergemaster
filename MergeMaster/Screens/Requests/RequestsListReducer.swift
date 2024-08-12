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
  let appStore: AppState

  var body: some ReducerOf<Self> {
    Reduce { (state, action) in
      switch action {
      case .viewAction(let action):
        return reduce(into: &state, viewAction: action)
      case .didLoad(let result):
        return handleLoadResult(result, state: &state)
      case .filter(let action):
        return reduceProjectFilter(state: &state, action: action)
      }
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
      guard let project = state.sections.first(where: { $0.project.id == projectId })?.project,
              let url = URL(string: project.webUrl) else { break }
      router.syncTrigger(.openProject(url))
    case .tapProjectSettings(let projectId):
      guard let index = state.sections.firstIndex(where: { $0.project.id == projectId }) else { break }
      state.settingsOpenedForProjectIdx = index
      let filter = state.filters[state.sections[index].project.id] ?? .empty
      state.filterState = .init(filter: filter)
    case .popoverDisplayed(let displayed):
      guard !displayed, let index = state.settingsOpenedForProjectIdx else { break }
      let projectId = state.sections[index].project.id
      if var filter = state.filterState?.filter, filter != state.filters[projectId] {
        filter.orExpressions = filter.orExpressions.filter { !$0.conditions.isEmpty }
        state.filters[projectId] = filter
        state.sections[index].filteredRequests = filteredRequests(
          requests: state.sections[index].requests,
          filter: filter
        )
        try? appStore.set(filters: state.filters)
      }
      state.settingsOpenedForProjectIdx = nil
    case .tapRequest(let id, let projectId):
      guard let section = state.sections.first(where: { $0.project.id == projectId }),
            let request = section.filteredRequests.first(where: { $0.id == id }),
            let url = URL(string: request.webURL)
      else { break }
      router.syncTrigger(.openRequest(url))
    }
    return .none
  }

  private func reduceProjectFilter(
    state: inout State,
    action: ProjectSettingsReducer.Action
  ) -> Effect<Action> {
    return .none
  }

  // MARK: - Actions

  private func handleLoadResult(
    _ result: Result<[AppFacade.ProjectRequests], Error>, state: inout State
  ) -> Effect<Action> {
    state.isLoading = false
    switch result {
    case .success(let requests):
      state.sections = requests.map { info in
        Section(
          project: info.project,
          requests: info.requests,
          filteredRequests: filteredRequests(requests: info.requests, filter: state.filters[info.project.id])
        )
      }
    case .failure(let failure):
      state.sections = []
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

  private func filteredRequests(requests: [MergeRequestInfo], filter: RequestsFilter?) -> [MergeRequestInfo] {
    guard let filter, !filter.isEmpty else { return requests }
    return requests
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
}

extension RequestsListReducer {
  enum Route {
    case settings(projectId: ProjectId)
    case changeProjects
    case logout
    case exit
    case openProject(URL)
    case openRequest(URL)
  }

  struct Section {
    var project: Project
    var requests: [MergeRequestInfo]
    var filteredRequests: [MergeRequestInfo]
  }

  struct State {
    var sections: [Section] = []
    var filters: [ProjectId: RequestsFilter] = [:]
    var isLoading: Bool = false
    var error: Error?
    var settingsOpenedForProjectIdx: Int?
    var filterState: ProjectSettingsReducer.State?
  }

  @CasePathable
  enum Action {
    case viewAction(RequestsListView.Action)
    case didLoad(requests: Result<[AppFacade.ProjectRequests], Error>)
    case filter(ProjectSettingsReducer.Action)
  }
}
