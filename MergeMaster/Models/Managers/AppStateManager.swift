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
    self.setupChangesBinding()
    self.setupNumberOfRequestsBinding()
  }

  private func setupChangesBinding() {
    requestsRepository.lastDataPublisher
    // disable cache
      .dropFirst()
      .filter { [filtersRepository] in $0.data.filters == filtersRepository.savedFilters }
      .scan((data: MergeRequestsFetchingData?.none, previous: MergeRequestsFetchingData?.none)) { (pair, data) in
        var pair = pair
        pair.previous = pair.data
        pair.data = data.data
        return pair
      }
      .compactMap { pair -> (data: IRequestsRepository.Requests, previous: IRequestsRepository.Requests)? in
        guard let data = pair.data?.response, let previous = pair.previous?.response else { return nil }
        return (data: data, previous: previous)
      }
      .map { [weak self] pair -> [NotificationRequest] in
        guard let self = self else { return [] }

        return self.notificationRequests(data: pair.data, previousData: pair.previous)
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] requests in
        self?.send(requests: requests)
      }
      .store(in: &bindings)
  }

  private func setupNumberOfRequestsBinding() {
    requestsRepository.lastDataPublisher
      .filter { [filtersRepository] in $0.data.filters == filtersRepository.savedFilters }
      .map { data in
        data.data.response.reduce(0) { (sum, projectRequests) in
          sum + projectRequests.value.count
        }
      }
      .receive(on: DispatchQueue.main)
      .sink { [menuWizard] numberOfRequests in
        menuWizard.setNumberOfRequests(numberOfRequests)
      }
      .store(in: &bindings)
  }

  private func send(requests: [NotificationRequest]) {
    requests.forEach { request in
      self.notificationsManager.schedule(
        id: request.id,
        content: request.content,
        trigger: request.trigger
      )
    }
  }
}


// MARK: - Notification Requests builders
extension AppStateManager {
  private func notificationRequests(
    data: IRequestsRepository.Requests,
    previousData: IRequestsRepository.Requests
  ) -> [NotificationRequest] {
    let changesByProject = self.changesByProject(data: data, previousData: previousData)
    let savedProjects = self.savedProjectsRepository.savedProjects

    var newRequests = [ProjectUpdate<MergeRequest>]()
    var newComments = [ProjectUpdate<NewCommentsInfo>]()
    var newCategories = [ProjectUpdate<StatusCategoryChangeInfo>]()

    savedProjects.forEach { project in
      guard let changes = changesByProject[project.id], !changes.isEmpty else { return }
      
      if changes.newRequests.isEmpty == false {
        newRequests.append(.init(project: project, updates: changes.newRequests))
      }
      if changes.newComments.isEmpty == false {
        newComments.append(.init(project: project, updates: changes.newComments))
      }
      if changes.statusCategoryChanges.isEmpty == false {
        newCategories.append(.init(project: project, updates: changes.statusCategoryChanges))
      }
    }

    return [
      newMergeRequestsNotificationRequest(newRequestsByProject: newRequests),
      newCommentsNotificationRequests(newCommentsByProject: newComments),
      newStatusCategoryNotificationRequests(newStatusCategoriesByProject: newCategories)
    ].compactMap { $0 }
  }

  private func changesByProject(
    data: IRequestsRepository.Requests,
    previousData: IRequestsRepository.Requests
  ) -> ChangesByProject {

    return data.reduce(into: ChangesByProject()) { (result, pair) in
      let (projectId, requests) = pair

      if let previousRequests = previousData[projectId] {
        result[projectId] = projectUpdates(requests: requests, previousRequests: previousRequests)
      } else {
        result[projectId] = ProjectUpdates(newRequests: requests)
      }
    }
  }

  private func projectUpdates(requests: [MergeRequest], previousRequests: [MergeRequest]) -> ProjectUpdates {
    let prevRequestsById = previousRequests.reduce(into: [MergeRequest.ID: MergeRequest](), { $0[$1.id] = $1 })
    var newRequests = [MergeRequest]()
    var newComments = [NewCommentsInfo]()
    var statusCategoryChanges = [StatusCategoryChangeInfo]()
    requests.forEach { request in
      if let prevRequest = prevRequestsById[request.id] {
        let numberOfCommentsDiff = request.numberOfComments - prevRequest.numberOfComments
        if numberOfCommentsDiff > 0 {
          newComments.append(NewCommentsInfo(request: request, numberOfNewComments: numberOfCommentsDiff))
        }
        let status = request.detailedMergeStatus
        let prevStatus = prevRequest.detailedMergeStatus
        if status.category != prevStatus.category {
          statusCategoryChanges.append(
            StatusCategoryChangeInfo(
              request: request,
              status: status,
              previousStatus: prevStatus
            )
          )
        }
      } else {
        newRequests.append(request)
      }
    }

    return ProjectUpdates(
      newRequests: newRequests,
      newComments: newComments,
      statusCategoryChanges: statusCategoryChanges
    )
  }

  private func newMergeRequestsNotificationRequest(newRequestsByProject: [ProjectUpdate<MergeRequest>]) -> NotificationRequest? {
    guard !newRequestsByProject.isEmpty else { return nil }

    var content = NotificationContent(category: .newRequests)
    let id: String
    if newRequestsByProject.count == 1, newRequestsByProject[0].updates.count == 1 {
      let project = newRequestsByProject[0].project
      let request = newRequestsByProject[0].updates[0]
      content.title = "1 new Merge Request"
      content.subtitle = request.title

      var bodyComponents = [String]()
      bodyComponents.append("project: " + project.name)
      bodyComponents.append("author: " + (request.author.username ?? request.author.name))
      content.body = bodyComponents.joined(separator: ", ")
      // Если всего 1 новый реквест - даем на него ссылку
      content.userInfo = ["URL": request.webUrl]
      id = String(request.id)
    } else {
      let projects = newRequestsByProject.map { $0.project }
      let newRequests = newRequestsByProject.flatMap { $0.updates }
      let numberOfNewRequests = newRequests.count
      content.title = "\(newRequests.count) new Merge Requests"
      content.subtitle = newRequests[0].title + " +\(numberOfNewRequests - 1) more"
      if projects.count == 1 {
        content.body = projects[0].name
      } else {
        let projectNames = projects.map {$0.name }
        content.body = "projects: " + joinTitlesForNotification(titles: projectNames)
      }
      id = newRequests.map { String($0.id) }.joined(separator: ";")
    }
    return NotificationRequest(
      id: id,
      content: content,
      trigger: .immediately
    )
  }

  private func newCommentsNotificationRequests(newCommentsByProject: [ProjectUpdate<NewCommentsInfo>]) -> NotificationRequest? {
    guard newCommentsByProject.isEmpty == false else { return nil }

    var content = NotificationContent(category: .newComments)
    let flattenInfo = newCommentsByProject.flatMap { $0.updates }
    let numberOfNewComments = flattenInfo.reduce(0, { $0 + $1.numberOfNewComments })

    if numberOfNewComments == 1 {
      content.title = "1 new comment"
    } else {
      content.title = "\(numberOfNewComments) new comments"
    }
    if flattenInfo.count == 1 {
      let project = newCommentsByProject[0].project
      let info = flattenInfo[0]
      content.subtitle = info.request.title
      content.body = "project: " + project.name
      content.userInfo = ["URL": info.request.webUrl]
    } else {
      let fullTitle = flattenInfo.map { $0.request.title }.joined(separator: ", ")
      content.subtitle = "requests: " + fullTitle
    }

    return NotificationRequest(
      id: "new_comments",
      content: content,
      trigger: .immediately
    )
  }

  private func newStatusCategoryNotificationRequests(newStatusCategoriesByProject: [ProjectUpdate<StatusCategoryChangeInfo>]) -> NotificationRequest? {
    guard newStatusCategoriesByProject.isEmpty == false else { return nil }

    var content = NotificationContent(category: .newStatusCategories)
    let flattenInfo = newStatusCategoriesByProject.flatMap { $0.updates }

    content.title = "Status category was changed"
    if flattenInfo.count == 1 {
      let info = flattenInfo[0]
      content.subtitle = "\(info.previousStatus.title) → \(info.status.title)"
      content.body = info.request.title
      content.userInfo = ["URL": info.request.webUrl]
    } else {
      content.subtitle = "requests: " + joinTitlesForNotification(titles: flattenInfo.map { $0.request.title })
    }

    return NotificationRequest(
      id: "new_status_categories",
      content: content,
      trigger: .immediately
    )
  }
}

// MARK: - Helpers
extension AppStateManager {
  @inline(__always)
  private func joinTitlesForNotification(titles: [String]) -> String {
    let fullTitle = titles.joined(separator: ", ")
    let maxLength = 50
    if fullTitle.count > maxLength {
      return String(fullTitle.prefix(maxLength)) + "..."
    } else {
      return fullTitle
    }
  }
}

// MARK: - Nested types
extension AppStateManager {
  private struct NewCommentsInfo {
    var request: MergeRequest
    var numberOfNewComments: Int
  }

  private struct StatusCategoryChangeInfo {
    var request: MergeRequest
    var status: MergeRequest.DetailedStatus
    var previousStatus: MergeRequest.DetailedStatus
  }

  private struct ProjectUpdates {
    var newRequests: [MergeRequest] = []
    var newComments: [NewCommentsInfo] = []
    var statusCategoryChanges: [StatusCategoryChangeInfo] = []

    var isEmpty: Bool {
      newRequests.isEmpty && newComments.isEmpty && statusCategoryChanges.isEmpty
    }
  }

  private struct ProjectUpdate<Update> {
    var project: Project
    var updates: [Update]
  }

  private typealias ChangesByProject = [ProjectId: ProjectUpdates]

  private struct NotificationRequest {
    var id: String
    var content: NotificationContent
    var trigger: NotificationTrigger
  }
}
