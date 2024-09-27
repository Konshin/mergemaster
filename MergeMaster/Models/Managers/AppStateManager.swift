//
//  AppStateManager.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 27.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Combine
import Foundation

final class AppStateManager {
  private let requestsRepository: IRequestsRepository
  private let filtersRepository: IFiltersRepository
  private let menuWizard: IMenuWizard
  private var bindings = Set<AnyCancellable>()

  init(
    requestsRepository: IRequestsRepository,
    filtersRepository: IFiltersRepository,
    menuWizard: IMenuWizard
  ) {
    self.requestsRepository = requestsRepository
    self.filtersRepository = filtersRepository
    self.menuWizard = menuWizard

    setup()
  }

  // MARK: - private

  private func setup() {
    setupNotificationsBinding()
    setupNumberOfRequestsBinding()
  }

  private func setupNotificationsBinding() {
    requestsRepository.lastDataPublisher
    // disable cached
      .dropFirst()
      .filter { [filtersRepository] in $0.filters == filtersRepository.savedFilters }
      .scan((data: MergeRequestsFetchingData?.none, previous: MergeRequestsFetchingData?.none)) { (pair, data) in
        var pair = pair
        pair.previous = pair.data
        pair.data = data
        return pair
      }
      .compactMap { pair -> (data: MergeRequestsFetchingData, previous: MergeRequestsFetchingData)? in
        guard let data = pair.data, let previous = pair.previous else { return nil }
        return (data: data, previous: previous)
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] pair in
        self?.notifyAboutDiffIfNeeded(data: pair.data, previousData: pair.previous)
      }
      .store(in: &bindings)
  }

  private func setupNumberOfRequestsBinding() {
    requestsRepository.lastDataPublisher
      .filter { [filtersRepository] in $0.filters == filtersRepository.savedFilters }
      .map { data in
        data.response.reduce(0) { (sum, projectRequests) in
          sum + projectRequests.value.count
        }
      }
      .receive(on: DispatchQueue.main)
      .sink { [menuWizard] numberOfRequests in
        menuWizard.setNumberOfRequests(numberOfRequests)
      }
      .store(in: &bindings)
  }

  private func notifyAboutDiffIfNeeded(
    data: MergeRequestsFetchingData,
    previousData: MergeRequestsFetchingData
  ) {
    let requests = data.response.reduce([MergeRequest]()) { (result, projectRequests) in
      result + projectRequests.value
    }
    let oldRequests = previousData.response.reduce([MergeRequest]()) { (result, projectRequests) in
      result + projectRequests.value
    }
    notifyAboutNewRequestsIfNeeded(oldRequests: oldRequests, requests: requests)
    notifyAboutNewCommentsIfNeeded(oldRequests: oldRequests, requests: requests)
  }

  private func notifyAboutNewRequestsIfNeeded(
    oldRequests: [MergeRequest],
    requests: [MergeRequest]
  ) {
    if requests.count > oldRequests.count {
      let numberOfNewRequests = requests.count - oldRequests.count

      let n = NSUserNotification()
      if numberOfNewRequests == 1 {
        n.title = "1 new Merge Request"
      } else {
        n.title = "\(numberOfNewRequests) new Merge Requests"
      }

      if let newRequest = requests.first(where: { new in !oldRequests.contains(where: { $0.id == new.id }) }) {
        // Если всего 1 новый реквест - даем на него ссылку
        n.userInfo = ["URL": newRequest.webUrl]
      }

      n.identifier = "new_request"
      n.deliveryDate = Date()

      NSUserNotificationCenter.default.scheduleNotification(n)
    }
  }

  private func notifyAboutNewCommentsIfNeeded(
    oldRequests: [MergeRequest],
    requests: [MergeRequest]
  ) {
    let commentsBefore = oldRequests.reduce(into: [Int: Int]()) { (result, request) in
      result[request.id] = request.numberOfComments
    }
    let commentsAfter = requests.reduce(into: [Int: Int]()) { (result, request) in
      result[request.id] = request.numberOfComments
    }
    var newComments = 0
    let requestsWithNewComments = requests.filter { request in
      let before = commentsBefore[request.id] ?? 0
      let after = commentsAfter[request.id] ?? 0
      let new = after - before
      let hasNew = new > 0
      if hasNew {
        newComments += new
      }
      return hasNew
    }
    guard !requestsWithNewComments.isEmpty else { return }

    let n = NSUserNotification()
    if requestsWithNewComments.count == 1 {
      let request = requestsWithNewComments[0]
      n.title = "1 new comment"
      n.subtitle = request.title
      n.userInfo = ["URL": request.webUrl]
    } else {
      let titles = requestsWithNewComments.map { $0.title }.joined(separator: ", ")
      n.title = "\(newComments) new comments"
      n.subtitle = titles
    }

    n.identifier = "new_comments"
    n.deliveryDate = Date()

    NSUserNotificationCenter.default.scheduleNotification(n)
  }
}
