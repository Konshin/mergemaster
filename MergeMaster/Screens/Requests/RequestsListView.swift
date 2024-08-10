//
//  RequestsListView.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI
import ComposableArchitecture

struct RequestsListView: View {
  @ObservedObject
  private(set) var store: ViewStore<State, Action>

  var body: some View {
    VStack(spacing: 0) {
      header()
      switch store.content {
      case .loading:
        skeletons()
      case .sections(let sections):
        List {
          ForEach(sections) { section in
            self.section(section: section)
          }
        }
      case .error(let error):
        errorView(error)
      }
    }
    .listStyle(.plain)
    .frame(width: 400, height: 250)
    .onAppear {
      store.send(.appeared)
    }
  }
}

// MARK: - Subveiws
private extension RequestsListView {

  @ViewBuilder
  private func skeletons() -> some View {
    List {
      SwiftUI.Section {
        ForEach(0..<3) { _ in
          skeletonRow()
        }
      } header: {
        SkeletonView()
          .frame(width: 100, height: 8)
      }
    }
  }

  @ViewBuilder
  private func skeletonRow() -> some View {
    HStack {
      VStack(alignment: .leading) {
        SkeletonView()
          .frame(width: 160, height: 12)
        SkeletonView()
          .frame(width: 60, height: 8)
      }
      Spacer()
    }
    .frame(height: 50)
  }

  @ViewBuilder
  private func errorView(_ text: String) -> some View {
    ErrorView(text, reload: { store.send(.reload) })
  }

  @ViewBuilder
  private func header() -> some View {
    ToolbarView(title: "Merge requests") {
      Button {
        store.send(.changeProjects)
      } label: {
        Image(systemName: "list.star")
      }
    } trailingViews: {
      Button {
        store.send(.changeProjects)
      } label: {
        Image(systemName: "rectangle.portrait.and.arrow.right")
      }
      Button {
        store.send(.changeProjects)
      } label: {
        Image(systemName: "xmark")
      }
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func section(section: Section) -> some View {
    SwiftUI.Section {
      ForEach(section.items) { item in
        row(item)
      }
    } header: {
      HStack {
        Button {
          store.send(.tapProject(section.id))
        } label: {
          HStack(spacing: 2) {
            Text(section.name)
            Image(systemName: "link")
          }
        }
        .buttonStyle(.link)
        Spacer()
        Button {
          store.send(.tapProjectSettings(section.id))
        } label: {
          Image(systemName: "slider.horizontal.3")
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
      }
    }
  }

  @ViewBuilder
  private func row(_ item: Item) -> some View {
    HStack(alignment: .bottom) {
      VStack(alignment: .leading, spacing: 4) {
        Text(item.title)
          .lineLimit(3)
        Text("Author: ").foregroundColor(.secondary) + Text(item.author)
      }
      Spacer()
      if item.isApprovedByUser {
        Text("Approved by you").foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 2)
  }
}

extension RequestsListView {
  struct Section: Equatable, Identifiable {
    var id: ProjectId
    var name: String
    var items: [Item]
  }

  struct Item: Identifiable, Equatable {
    var id: Int
    var title: String
    var author: String
    var isApprovedByUser: Bool
  }

  enum Content: Equatable {
    case loading
    case sections([Section])
    case error(String)
  }

  struct State: Equatable {
    var content: Content
  }

  enum Action {
    case appeared
    case reload
    case changeProjects
    case logout
    case exit
    case tapProject(ProjectId)
    case tapProjectSettings(ProjectId)
  }
}

#Preview {
  let makeItems: (Int) -> [RequestsListView.Item] = { count in
    return (0..<count).map { id in
      RequestsListView.Item(
        id: id,
        title: Array<String>(repeating: "Merge request #\(id)", count: id + 1).joined(separator: "\n"),
        author: "Author of MR",
        isApprovedByUser: id % 3 == 0
      )
    }
  }
  let sections: [RequestsListView.Section] = [
    .init(id: 0, name: "Your first project", items: makeItems(3)),
    .init(id: 1, name: "Your project #2", items: makeItems(1)),
    .init(id: 2, name: "Third project", items: makeItems(4)),
  ]
  let state = RequestsListView.State(
    content: .loading
  )
  return RequestsListView(
    store: .preview(state: state, reducer: {
      Reduce { (state, action) in
        switch action {
        case .appeared:
          return .run { send in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            await send(.reload)
          }
        case .reload:
          state.content = .sections(sections)
          return .none
        default:
          return .none
        }
      }
    })
  )
}
