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
    let reducer = ProjectsListReducer(router: router, appFacade: dependencies.appFacade, appState: dependencies.appState)
    let state = ProjectsListReducer.State(selectedProjects: dependencies.appState.selectedProjects.value)
    let store = StoreOf<ProjectsListReducer>(initialState: state) { reducer }
    let adapter = ProjectsListAdapter()
    let viewStore = ViewStore.init(store, observe: adapter.adapt(state:), send: adapter.adapt(action:))
    return ProjectsListView(store: viewStore)
  }
}
