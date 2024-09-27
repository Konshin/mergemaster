//
//  RequestsListAssembly.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation
import ComposableArchitecture

struct RequestsListAssembly {
  let dependencies: Dependencies

  func makeView(router: Router<RequestsListReducer.Route>) -> RequestsListView {
    let reducer = RequestsListReducer(
      router: router, 
      interactor: RequestsListInteractor(
        filtersRepository: dependencies.filtersRepository,
        savedProjectsRepository: dependencies.selectedProjectsRepository,
        requestsRepository: dependencies.requestsRepository
      )
    )
    let state = RequestsListReducer.State(filters: dependencies.filtersRepository.savedFilters)
    let store = Store(
      initialState: state,
      reducer: {
        reducer
          .ifLet(
            \.filterState,
             action: \.filter,
             then: {
               ProjectSettingsReducer(router: .empty)
             }
          )
      }
    )

    // activate polling
    store.send(.startPolling)

    let adapter = RequestsListAdapter()
    return RequestsListView(
      store: ViewStore(
        store,
        observe: adapter.adapt(state:),
        send: adapter.adapt(action:)
      ),
      popover: {
        if let store = store.optionalScope(
          state: \.filterState,
          action: \.filter
        ) {
          let adapter = ProjectSettingsAdapter()
          return ProjectSettingsView(
            store: .init(
              store, 
              observe: adapter.adapt(state:),
              send: adapter.adapt(action:)
            )
          )
        } else {
          return nil
        }
      }
    )
  }
}
