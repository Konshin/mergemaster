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
  private let notificationsManager: INotificationsManager
  private let savedProjectsRepository: ISavedProjectsRepository
  private var bindings = Set<AnyCancellable>()

  init(
    requestsRepository: IRequestsRepository,
    filtersRepository: IFiltersRepository,
    menuWizard: IMenuWizard,
    notificationsManager: INotificationsManager,
    savedProjectsRepository: ISavedProjectsRepository
  ) {
    self.requestsRepository = requestsRepository
    self.filtersRepository = filtersRepository
    self.menuWizard = menuWizard
    self.notificationsManager = notificationsManager
    self.savedProjectsRepository = savedProjectsRepository

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
      .compactMap { pair -> (data: IRequestsRepository.Requests, previous: IRequestsRepository.Requests)? in
        guard let data = pair.data?.response, let previous = pair.previous?.response else { return nil }
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
    data: IRequestsRepository.Requests,
    previousData: IRequestsRepository.Requests
  ) {
    notifyAboutNewRequestsIfNeeded(
      requests: data,
      previousRequests: previousData
    )
    notifyAboutNewCommentsIfNeeded(
      requestsByProjects: data,
      previousRequestsByProjects: previousData
    )
  }

  private func notifyAboutNewRequestsIfNeeded(
    requests: IRequestsRepository.Requests,
    previousRequests: IRequestsRepository.Requests
  ) {
    var newRequestsByProject = IRequestsRepository.Requests()
    requests.forEach { (projectId, thisProjectRequests) in
      guard let thisProjectPrevRequests = previousRequests[projectId] else {
        // all requests are new
        newRequestsByProject[projectId] = thisProjectRequests
        return
      }
      let diff = thisProjectRequests.difference(from: thisProjectPrevRequests) { $0.id == $1.id }
      let newProjectRequests = diff.compactMap { change in
        switch change {
        case let .insert(_, element, _):
          return element
        case .remove:
          return nil
        }
      }
      if newProjectRequests.isEmpty == false {
        newRequestsByProject[projectId] = newProjectRequests
      }
    }
    if newRequestsByProject.isEmpty == false {
      var content = NotificationContent(category: .newRequests)
      let id: String
      if newRequestsByProject.count == 1, newRequestsByProject.values.first?.count == 1 {
        let projectId = newRequestsByProject.keys.first!
        let request = newRequestsByProject[projectId]!.first!
        content.title = "1 new Merge Request"
        content.subtitle = request.title

        var bodyComponents = [String]()
        if let project = savedProjectsRepository.savedProject(id: projectId) {
          bodyComponents.append("project: " + project.name)
        }
        bodyComponents.append("author: " + (request.author.username ?? request.author.name))
        content.body = bodyComponents.joined(separator: ", ")
        // Если всего 1 новый реквест - даем на него ссылку
        content.userInfo = ["URL": request.webUrl]
        id = String(request.id)
      } else {
        let projectIds = newRequestsByProject.keys
        let newRequests = projectIds.compactMap { newRequestsByProject[$0] }.flatMap { $0 }
        let numberOfNewRequests = newRequestsByProject.values.reduce(0, { $0 + $1.count })
        content.title = "\(newRequests.count) new Merge Requests"
        content.subtitle = newRequests[0].title + " +\(numberOfNewRequests - 1) more"
        if projectIds.count == 1, let project = savedProjectsRepository.savedProject(id: projectIds.first!) {
          content.body = project.name
        } else {
          let projectNames = projectIds.compactMap { savedProjectsRepository.savedProject(id: $0)?.name }
          if !projectNames.isEmpty {
            content.body = "projects: " + projectNames.joined(separator: ", ")
          }
        }
        id = newRequests.map { String($0.id) }.joined(separator: ";")
      }

      notificationsManager.schedule(
        id: id,
        content: content,
        trigger: .immediately
      )
    }
  }

  private func notifyAboutNewCommentsIfNeeded(
    requestsByProjects: IRequestsRepository.Requests,
    previousRequestsByProjects: IRequestsRepository.Requests
  ) {
    let requestsBefore = previousRequestsByProjects.values.flatMap { $0 }
    let commentsBefore = requestsBefore.reduce(into: [Int: Int]()) { (result, request) in
      result[request.id] = request.numberOfComments
    }

    let requests = requestsByProjects.values.flatMap { $0 }
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

    var content = NotificationContent(category: .newComments)
    if requestsWithNewComments.count == 1 {
      let request = requestsWithNewComments[0]
      content.title = "1 new comment"
      content.subtitle = request.title
      content.userInfo = ["URL": request.webUrl]
    } else {
      let titles = requestsWithNewComments.map { $0.title }.joined(separator: ", ")
      content.title = "\(newComments) new comments"
      content.subtitle = titles
    }

    notificationsManager.schedule(
      id: "new_comments",
      content: content,
      trigger: .immediately
    )
  }
}
