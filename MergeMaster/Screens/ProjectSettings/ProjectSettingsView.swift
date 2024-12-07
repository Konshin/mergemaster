//
//  ProjectSettingsView.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 11.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct ProjectSettingsView: View {
  @ObservedObject
  private(set) var store: ViewStore<State, Action>

  var body: some View {
      VStack {
        ForEach(store.orExpressions) { expression in
          self.expression(
            expression,
            addSeparator: expression.id != store.orExpressions.last?.id
          )
        }
      }
      .textFieldStyle(.roundedBorder)
    .padding(8)
    .frame(width: 300)
  }
}

// MARK: - Subviews
extension ProjectSettingsView {

  @ViewBuilder
  private func expression(_ expression: Expression, addSeparator: Bool) -> some View {
    VStack(alignment: .center) {
      ForEach(expression.conditions) { condition in
        line(condition: condition, expressionId: expression.id)
      }
      Button("Add condition") {
        store.send(.addCondition(expressionId: expression.id))
      }
      .buttonStyle(.plain)
      .foregroundColor(.accentColor)
      if addSeparator {
        HStack {
          Rectangle()
            .foregroundColor(Color(NSColor.separatorColor))
            .frame(height: 1)
          Text("OR")
            .foregroundColor(.secondary)
          Rectangle()
            .foregroundColor(Color(NSColor.separatorColor))
            .frame(height: 1)
        }
      }
    }
  }

  @ViewBuilder
  private func line(condition: Condition, expressionId: Int) -> some View {
    HStack {
      Picker(
        "",
        selection: Binding(
          get: { condition.property },
          set: {
            store.send(
              .changeProperty(
                expressionId: expressionId,
                conditionId: condition.id,
                property: $0
              )
            )
          }
        ),
        content: {
          ForEach([Property.assignee, .author, .reviewers, .labels], id: \.name) { property in
            Text(property.name).tag(property)
          }
        }
      )
      .fixedSize()
      Picker(
        "",
        selection: Binding(
          get: { condition.operator },
          set: {
            store.send(
              .changeOperator(
                expressionId: expressionId,
                conditionId: condition.id,
                operator: $0
              )
            )
          }
        ),
        content: {
          ForEach([Operator.equal, .notEqual, .contains], id: \.symbol) { `operator` in
            Text(`operator`.symbol).tag(`operator`)
          }
        }
      )
      .fixedSize()
      TextField(
        "",
        text: .init(
          get: { condition.value },
          set: {
            store.send(
              .changeValue(
                expressionId: expressionId,
                conditionId: condition.id,
                value: $0
              )
            )
          }
        )
      )
      Button {
        store.send(
          .deleteCondition(
            expressionId: expressionId,
            conditionId: condition.id
          )
        )
      } label: {
        Image(systemName: "xmark")
      }
      .buttonStyle(.plain)
      .foregroundColor(.red)
    }
  }
}

// MARK: - Types
extension ProjectSettingsView {
  typealias Property = RequestsFilter.Property
  typealias Operator = RequestsFilter.Condition.Operator

  struct State: Equatable {
    var orExpressions: [Expression]
  }

  struct Expression: Equatable, Identifiable {
    var id: Int
    var conditions: [Condition]
  }

  struct Condition: Equatable, Identifiable {
    var id: Int
    var property: Property
    var `operator`: Operator
    var value: String
  }

  enum Action {
    case appeared
    case addCondition(expressionId: Int)
    case changeProperty(expressionId: Int, conditionId: Int, property: Property)
    case changeOperator(expressionId: Int, conditionId: Int, operator: Operator)
    case changeValue(expressionId: Int, conditionId: Int, value: String)
    case deleteCondition(expressionId: Int, conditionId: Int)
  }
}

#Preview {
  let state = ProjectSettingsView.State(
    orExpressions: [
      .init(
        id: 0,
        conditions: [
          .init(id: 0, property: .assignee, operator: .equal, value: "a.konshin"),
          .init(id: 1, property: .author, operator: .notEqual, value: "ANY")
        ]
      ),
      .init(
        id: 1,
        conditions: [
          .init(id: 0, property: .assignee, operator: .contains, value: "example.user"),
        ]
      ),
      .init(id: 2, conditions: [])
    ]
  )
  return ProjectSettingsView(store: .preview(state: state, reducer: {}))
}

private extension ProjectSettingsView.Property {
  var name: String {
    switch self {
    case .author:
      return "Author"
    case .assignee:
      return "Assignee"
    case .labels:
      return "Labels"
    case .reviewers:
      return "Reviewers"
    }
  }
}

private extension ProjectSettingsView.Operator {
  var symbol: String {
    switch self {
    case .equal:
      return "="
    case .notEqual:
      return "≠"
    case .contains:
      return "⊂"
    }
  }
}
