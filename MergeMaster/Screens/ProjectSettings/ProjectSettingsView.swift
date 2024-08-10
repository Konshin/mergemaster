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
    .animation(
      .default,
      value: store.orExpressions
        .map({ $0.conditions.count })
        .reduce(0, +))
    .frame(
      minWidth: 300,
      maxWidth: 300,
      minHeight: 100,
      alignment: .topLeading
    )
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
          ForEach(Property.allCases, id: \.name) { property in
            Text(property.name).tag(property)
          }
        }
      )
      .frame(width: 100, alignment: .trailing)
      TextField("", text: .constant(condition.value))
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
  enum Property: CaseIterable {
    case author, assignee

    fileprivate var name: String {
      switch self {
      case .author:
        return "Author"
      case .assignee:
        return "Assignee"
      }
    }
  }

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
    var value: String
  }

  enum Action {
    case addCondition(expressionId: Int)
    case changeProperty(expressionId: Int, conditionId: Int, property: Property)
    case deleteCondition(expressionId: Int, conditionId: Int)
  }

//  enum Property {
//    case assignee, author
//
//    var title: String {
//
//    }
//  }
}

#Preview {
  let state = ProjectSettingsView.State(
    orExpressions: [
      .init(
        id: 0,
        conditions: [
          .init(id: 0, property: .assignee, value: "a.konshin"),
          .init(id: 1, property: .author, value: "ANY")
        ]
      ),
      .init(
        id: 1,
        conditions: [
          .init(id: 0, property: .assignee, value: "example.user"),
        ]
      ),
      .init(id: 2, conditions: [])
    ]
  )
  return ProjectSettingsView(store: .preview(state: state, reducer: {}))
}
