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
    if state.isLoading, state.projectRequests.isEmpty {
      content = .loading
    } else if let error = state.error {
      content = .error(error.localizedDescription)
    } else {
      content = .sections(
        state.projectRequests.map { requestInfo in
            .init(
              id: requestInfo.project.id,
              name: requestInfo.project.name,
              items: requestInfo.requests.map(item(request:))
            )
        }
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
