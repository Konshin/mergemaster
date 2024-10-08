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
  private(set) var popover: () -> ProjectSettingsView?

  var body: some View {
    VStack(spacing: 0) {
      header()
      switch store.content {
      case .loading:
        skeletons()
      case .data(let data):
        List {
          ForEach(data.sections) { section in
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
        store.send(.logout)
      } label: {
        Image(systemName: "rectangle.portrait.and.arrow.right")
      }
      Button {
        store.send(.exit)
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
        row(item, sectionId: section.id)
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
        .popover(
          isPresented: store.binding(
            get: { $0.settingsOpenedForSectionId == section.id },
            send: { .popoverDisplayed($0) }
          ),
          content: {
            popover(sectionId: section.id)
          }
        )
      }
    }
  }

  @ViewBuilder
  private func popover(sectionId: ProjectId) -> some View {
    if let popover = self.popover() {
      popover
    } else {
      Text("The popover is here")
    }
  }

  @ViewBuilder
  private func row(_ item: Item, sectionId: ProjectId) -> some View {
    RequestListRow(item: item)
    .onTapGesture {
      store.send(.tapRequest(id: item.id, projectId: sectionId))
    }
  }
}

extension RequestsListView {
  struct Section: Equatable, Identifiable {
    var id: ProjectId
    var name: String
    var items: [Item]
  }

  struct Data: Equatable {
    var sections: [Section]
    var settingsOpenedForSectionId: ProjectId?
  }

  typealias Item = RequestListRow.Item

  enum Content: Equatable {
    case loading
    case data(Data)
    case error(String)
  }

  struct State: Equatable {
    var content: Content

    var settingsOpenedForSectionId: ProjectId? {
      guard case .data(let data) = content else {
        return nil
      }
      return data.settingsOpenedForSectionId
    }
  }

  enum Action {
    case appeared
    case reload
    case changeProjects
    case logout
    case exit
    case tapProject(ProjectId)
    case tapProjectSettings(ProjectId)
    case tapRequest(id: Int, projectId: ProjectId)
    case popoverDisplayed(Bool)
  }
}

#Preview {
  let makeItems: (Int) -> [RequestsListView.Item] = { count in
    let highlights: [RequestListRow.StatusHighlighting] = [.none, .red, .yellow]
    func statusHighlight(at index: Int) -> RequestListRow.StatusHighlighting {
      let idx = index % highlights.count
      return highlights[idx]
    }

    return (0..<count).map { id in
      RequestsListView.Item(
        id: id,
        title: Array<String>(repeating: "Merge request #\(id)", count: id + 1).joined(separator: "\n"),
        author: "Author of MR",
        status: "Some status",
        statusDescription: "Some description",
        statusHighlighting: statusHighlight(at: id)
      )
    }
  }
  let sections: [RequestsListView.Section] = [
    .init(id: 0, name: "Your first project", items: makeItems(3)),
    .init(id: 1, name: "Your project #2", items: makeItems(1)),
    .init(id: 2, name: "Third project", items: makeItems(4)),
  ]
  let state = RequestsListView.State(
    content: .data(.init(sections: sections))
  )
  RequestsListView(
    store: .preview(
      state: state,
      reducer: {
        Reduce { (state, action) in
          switch action {
          case .appeared:
            return .run { send in
              try? await Task.sleep(nanoseconds: 5_000_000_000)
              await send(.reload)
            }
          case .reload:
            state.content = .data(.init(sections: sections))
            return .none
          case .tapProject(let projectId):
            guard case .data(var data) = state.content else { break }
            data.settingsOpenedForSectionId = projectId
            state.content = .data(data)
          case .popoverDisplayed(let displayed):
            guard !displayed, case .data(var data) = state.content else { break }
            data.settingsOpenedForSectionId = nil
            state.content = .data(data)
          default:
            break
          }
          return .none
        }
      }),
    popover: { nil }
  )
}
