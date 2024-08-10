//
//  ProjectsListView.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 06.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct ProjectsListView: View {
  @ObservedObject
  var store: ViewStore<State, Action>
  @SwiftUI.State
  private var isSearchEnabled = false

  var body: some View {
    VStack {
      header()
      if store.filter == .all {
        TextField(
          "Repository or project name",
          text: store.binding(
            get: \.searchTerm,
            send: Action.update(searchTerm:)
          )
        )
        .textFieldStyle(.roundedBorder)
        .padding(.horizontal, 8)
      }
      if let error = store.error {
        errorView(error)
      } else {
        List {
          if store.isLoading {
            skeletons()
          } else {
            items(store.items, searchTerm: store.searchTerm)
          }
        }
        .listStyle(.plain)
      }
    }
    .padding(.vertical)
    .frame(width: 400, height: 250)
    .background(Color(.textBackgroundColor))
    .onAppear {
      store.send(.appeared)
    }
  }

  @ViewBuilder
  private func header() -> some View {
    ToolbarView(title: "Projects") {
      Picker(
        "Filter",
        selection: store.binding(
          get: \.filter,
          send: Action.changeFilter),
        content: {
          Text("All").tag(ProjectsFilter.all)
          Text("Selected (\(store.numberOfSelectedProjects))").tag(ProjectsFilter.selected)
        }
      )
      .pickerStyle(.segmented)
      .labelsHidden()
      .frame(width: 140)
    } trailingViews: {
      Button {
        store.send(.confirm)
      } label: {
        Text("Confirm")
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private func items(_ items: [Item], searchTerm: String) -> some View {
    if items.isEmpty {
      HStack {
        Spacer()
        Text(searchTerm.isEmpty ? "No projects available" : "No projects found for «\(searchTerm)»")
          .lineLimit(0)
          .foregroundColor(.secondary)
        Spacer()
      }
    } else {
      ForEach(store.items) { item in
        row(item: item)
          .background(Color(.textBackgroundColor))
          .onTapGesture {
            store.send(.setSelected(id: item.id, selected: !item.isSelected))
          }
      }
    }
  }

  @ViewBuilder
  private func row(item: Item) -> some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading) {
        Text(item.header ?? "")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Text(item.title)
          .font(.title3)
      }
      Spacer()
      Toggle(
        isOn: .constant(item.isSelected),
        label: {
          Text("Selected")
        }
      )
      .labelsHidden()
      .allowsHitTesting(false)
    }
  }

  @ViewBuilder
  private func skeletons() -> some View {
    ForEach(0..<3) { _ in
      skeletonRow()
    }
  }

  @ViewBuilder
  private func skeletonRow() -> some View {
    HStack {
      VStack(alignment: .leading) {
        SkeletonView()
          .frame(width: 30, height: 8)
        SkeletonView()
          .frame(width: 60, height: 12)
      }
      Spacer()
      SkeletonView()
        .frame(width: 10, height: 10)
    }
    .frame(height: 40)
  }

  @ViewBuilder
  private func errorView(_ error: String) -> some View {
    ErrorView(error, reload: { store.send(.reload) })
  }
}

extension ProjectsListView {
  enum ProjectsFilter {
    case all, selected
  }

  struct Item: Equatable, Identifiable {
    var id: ProjectId
    var title: String
    var header: String?
    var isSelected: Bool
  }

  struct State: Equatable {
    var items: [Item]
    var numberOfSelectedProjects: Int = 0
    var filter: ProjectsFilter = .all
    var searchTerm: String = ""
    var isLoading: Bool
    var error: String?
  }

  enum Action {
    case update(searchTerm: String)
    case setSelected(id: ProjectId, selected: Bool)
    case confirm
    case appeared
    case reload
    case changeFilter(ProjectsFilter)
  }
}

#Preview {
  let items = (0...2).map {
    ProjectsListView.Item(
      id: $0,
      title: "Repository #\($0)",
      header: "Some project",
      isSelected: false
    )
  }
  let state = ProjectsListView.State(
    items: items,
    isLoading: false,
    error: "Failed to load projects!"
  )
  return ProjectsListView(
    store: .preview(state: state, reducer: {
      Reduce { (state, action) in
        switch action {
        case .setSelected(let id, let selected):
          if let index = state.items.firstIndex(where: { $0.id == id }) {
            state.items[index].isSelected = selected
          }
        case .update(let searchTerm):
          state.searchTerm = searchTerm
        case .confirm, .appeared:
          break
        case .changeFilter(let filter):
          state.filter = filter
        case .reload:
          state.error = nil
        }
        return .none
      }
    })
  )
}
