//
//  ProjectSettingsAssembly.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 11.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct ProjectSettingsAssembly {
  struct Params {
    var filter: RequestsFilter
  }

  let dependencies: Dependencies
  let params: Params

  func makeView(router: Router<ProjectSettingsReducer.Route>) -> ProjectSettingsView {
    let reducer = ProjectSettingsReducer(router: router)
    let state = ProjectSettingsReducer.State(
      filter: params.filter
    )
    return ProjectSettingsView(
      store: .adapted(state: state, reducer: { reducer }, adapter: ProjectSettingsAdapter())
    )
  }
}
