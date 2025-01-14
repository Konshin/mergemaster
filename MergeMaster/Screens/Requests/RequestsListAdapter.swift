//
//  RequestsListAdapter.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct RequestsListAdapter: ViewAdapter {
  private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
  }()
  private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
  }()

  func adapt(state: RequestsListReducer.State) -> RequestsListView.State {
    let content: RequestsListView.Content
    if state.isLoading, state.sections.isEmpty {
      content = .loading
    } else if let error = state.error, state.sections.isEmpty {
      content = .error(error.localizedDescription)
    } else {
      content = .data(
        .init(
          sections: state.sections.map { section in
              .init(
                id: section.project.id,
                name: section.project.name,
                items: section.requests.map(item(request:))
              )
          },
          settingsOpenedForSectionId: state.settingsOpenedForProjectIdx.map { state.sections[$0].project.id }
        )
      )
    }
    return RequestsListView.State(
      content: content,
      lastUpdateDate: state.lastUpdateDate.map(dateString),
      isRefreshing: state.isLoading
    )
  }

  func adapt(action: RequestsListView.Action) -> RequestsListReducer.Action {
    .viewAction(action)
  }

  private func item(request: MergeRequest) -> RequestsListView.Item {
    return RequestsListView.Item(
      id: request.id,
      title: request.title,
      author: request.author.name,
      status: request.detailedMergeStatus.title,
      statusDescription: request.detailedMergeStatus.description,
      statusHighlighting: {
        switch request.detailedMergeStatus.category {
        case .waitingForResultOfSth:
          return .none
        case .userActionRequired:
          return .red
        case .readyToMerge:
          return .green
        }
      }()
    )
  }

  private func dateString(date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
      timeFormatter.string(from: date)
    } else {
      dateTimeFormatter.string(from: date)
    }
  }
}
