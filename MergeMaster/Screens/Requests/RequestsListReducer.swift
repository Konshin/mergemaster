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
  let interactor: IRequestsListInteractor

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
      return loadRequests(state: &state, allowCache: true)
    case .reload:
      return loadRequests(state: &state, allowCache: false)
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
      state.settingsOpenedForProjectIdx = nil

      let projectId = state.sections[index].project.id
      if var filter = state.filterState?.filter, filter != state.filters[projectId] {
        filter.orExpressions = filter.orExpressions.filter { !$0.conditions.isEmpty }
        state.filters[projectId] = filter
        interactor.update(filter: filter, for: projectId)
      }
      state.sections.removeAll()
      return loadRequests(state: &state, allowCache: false)
    case .tapRequest(let id, let projectId):
      guard let section = state.sections.first(where: { $0.project.id == projectId }),
            let request = section.requests.first(where: { $0.id == id }),
            let url = URL(string: request.webUrl)
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
    _ result: Result<[RequestsInfo], Error>, state: inout State
  ) -> Effect<Action> {
    state.isLoading = false
    switch result {
    case .success(let requests):
      state.sections = requests.map { info in
        Section(
          project: info.project,
          requests: info.requests
        )
      }
    case .failure(let failure):
      state.sections = []
      state.error = failure
    }
    return .none
  }

  private func loadRequests(state: inout State, allowCache: Bool) -> Effect<Action> {
    state.isLoading = true
    state.error = nil
    return .run { send in
      do {
        for try await data in interactor.requests(allowCache: allowCache) {
          await send(.didLoad(requests: .success(data.wrappedValue)))
        }
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
    case openRequest(URL)
  }

  struct Section {
    var project: Project
    var requests: [MergeRequest]
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
    case didLoad(requests: Result<[RequestsInfo], Error>)
    case filter(ProjectSettingsReducer.Action)
  }
}
