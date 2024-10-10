//
//  ProjectSettingsAdapter.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 11.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct ProjectSettingsAdapter: ViewAdapter {
  func adapt(state: ProjectSettingsReducer.State) -> ProjectSettingsView.State {
    var orExpressions = state.filter.orExpressions.enumerated().map { (idx, expr) in
      ProjectSettingsView.Expression(
          id: idx,
          conditions: expr.conditions.enumerated()
            .map { (idx, cond) in
              ProjectSettingsView.Condition(
                id: idx,
                property: cond.property,
                operator: cond.operator,
                value: cond.value)
            }
        )
    }
    // add empty
    if orExpressions.last?.conditions.isEmpty != true {
      orExpressions.append(.init(id: orExpressions.count, conditions: []))
    }
    return ProjectSettingsView.State(
      orExpressions: orExpressions
    )
  }


  func adapt(action: ProjectSettingsView.Action) -> ProjectSettingsReducer.Action {
    .viewAction(action)
  }
}
