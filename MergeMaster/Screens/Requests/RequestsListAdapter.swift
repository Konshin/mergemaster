//
//  RequestsListAdapter.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct RequestsListAdapter: ViewAdapter {
  func adapt(state: RequestsListReducer.State) -> RequestsListView.State {
    let content: RequestsListView.Content
    if state.isLoading, state.sections.isEmpty {
      content = .loading
    } else if let error = state.error {
      content = .error(error.localizedDescription)
    } else {
      content = .data(
        .init(
          sections: state.sections.map { section in
              .init(
                id: section.project.id,
                name: section.project.name,
                items: section.filteredRequests.map(item(request:))
              )
          },
          settingsOpenedForSectionId: state.settingsOpenedForProjectIdx.map { state.sections[$0].project.id }
        )
      )
    }
    return RequestsListView.State(
      content: content
    )
  }

  func adapt(action: RequestsListView.Action) -> RequestsListReducer.Action {
    .viewAction(action)
  }

  private func item(request: MergeRequestInfo) -> RequestsListView.Item {
    RequestsListView.Item(
      id: request.id,
      title: request.title,
      author: request.author.name,
      isApprovedByUser: false
    )
  }
}
