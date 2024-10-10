//
//  ProjectSettingsReducer.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 11.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ProjectSettingsReducer {

  let router: Router<Route>

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .viewAction(let action):
      return reduce(into: &state, viewAction: action)
    }
  }

  private func reduce(into state: inout State, viewAction: ProjectSettingsView.Action) -> Effect<Action> {
    switch viewAction {
    case .appeared:
      break
    case .addCondition(let expressionId):
      if state.filter.orExpressions.count <= expressionId {
        state.filter.orExpressions.append(.init(conditions: []))
      }
      guard let expressionIdx = index(of: expressionId, state: state) else { break }
      let itWasLastCondition = state.filter.orExpressions[expressionIdx].conditions.isEmpty
      state.filter.orExpressions[expressionIdx].conditions.append(
        .init(
          property: .assignee,
          value: ""
        )
      )
      if itWasLastCondition {
        // add empty expression
        state.filter.orExpressions.append(
          .init(conditions: [])
        )
      }
    case .changeProperty(let expressionId, let conditionId, let property):
      guard let indexPath = indexPath(expressionId: expressionId, conditionId: conditionId, state: state) else { break }
      state.filter.orExpressions[indexPath.section].conditions[indexPath.item].property = property
    case .changeOperator(let expressionId, let conditionId, let `operator`):
      guard let indexPath = indexPath(expressionId: expressionId, conditionId: conditionId, state: state) else { break }
      state.filter.orExpressions[indexPath.section].conditions[indexPath.item].operator = `operator`
    case .deleteCondition(let expressionId, let conditionId):
      guard let indexPath = indexPath(expressionId: expressionId, conditionId: conditionId, state: state) else { break }
      let isLastExpression = indexPath.section == state.filter.orExpressions.count - 1
      if !isLastExpression, state.filter.orExpressions[indexPath.section].conditions.count == 1 {
        // remove the entire expression
        state.filter.orExpressions.remove(at: indexPath.section)
      } else {
        state.filter.orExpressions[indexPath.section].conditions.remove(at: indexPath.item)
      }
    case .changeValue(let expressionId, let conditionId, let value):
      guard let indexPath = indexPath(expressionId: expressionId, conditionId: conditionId, state: state) else { break }
      state.filter.orExpressions[indexPath.section].conditions[indexPath.item].value = value
    }
    return .none
  }

  // MARK: - Actions

  private func index(of expressionId: Int, state: State) -> Int? {
    guard state.filter.orExpressions.count > expressionId else { return nil }
    return expressionId
  }

  private func indexPath(expressionId: Int, conditionId: Int, state: State) -> IndexPath? {
    guard state.filter.orExpressions.count > expressionId,
            state.filter.orExpressions[expressionId].conditions.count > conditionId else { return nil }
    return IndexPath(item: conditionId, section: expressionId)
  }
}

extension ProjectSettingsReducer {
  enum Route {}

  struct State {
    var filter: RequestsFilter
  }

  enum Action {
    case viewAction(ProjectSettingsView.Action)
  }
}
