//
//  RequestsListAssembly.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct RequestsListAssembly {
  let dependencies: Dependencies

  func makeView(router: Router<RequestsListReducer.Route>) -> RequestsListView {
    let reducer = RequestsListReducer(router: router, appFacade: dependencies.appFacade)
    let state = RequestsListReducer.State()
    return RequestsListView(
      store: .adapted(state: state, reducer: { reducer }, adapter: RequestsListAdapter())
    )
  }
}
