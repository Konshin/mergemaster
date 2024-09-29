//
//  NotificationsManager.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 29.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import UserNotifications
import AppKit

protocol INotificationsManager {
  var isAuthorized: Bool { get async }
  var delegate: NotificationsManagerDelegate? { get set }
  func authorizeIfNeeded() async -> Bool
  func schedule(
    id: String,
    content: NotificationContent,
    trigger: NotificationTrigger
  )
}

protocol NotificationsManagerDelegate: AnyObject {
  func displayRequests()
}

final class NotificationsManager: NSObject {
  private let nCenter = UNUserNotificationCenter.current()
  weak var delegate: NotificationsManagerDelegate?

  override init() {
    super.init()
    nCenter.delegate = self
  }
}

extension NotificationsManager: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    if let url = response.notification.request.content.userInfo["URL"] as? String,
       let URL = URL(string: url)
    {
      NSWorkspace.shared.open(URL)
    } else {
      delegate?.displayRequests()
    }
  }
}

extension NotificationsManager: INotificationsManager {

  var isAuthorized: Bool {
    get async {
      let settings = await nCenter.notificationSettings()
      return settings.authorizationStatus == .authorized
    }
  }

  @discardableResult
  func authorizeIfNeeded() async -> Bool {
    let isAuthorized = await self.isAuthorized
    guard !isAuthorized else { return true }
    do {
      try await nCenter.requestAuthorization(options: [.alert, .sound])
      return true
    } catch {
      print("failed to authorize: \(error)")
      return false
    }
  }

  func schedule(
    id: String,
    content: NotificationContent,
    trigger: NotificationTrigger
  ) {
    let nContent = UNMutableNotificationContent()
    if let title = content.title {
      nContent.title = title
    }
    if let subtitle = content.subtitle {
      nContent.subtitle = subtitle
    }
    if let body = content.body {
      nContent.body = body
    }
    if let userInfo = content.userInfo {
      nContent.userInfo = userInfo
    }
    nContent.categoryIdentifier = content.category.rawValue
    let nTrigger: UNNotificationTrigger
    switch trigger {
    case .immediately:
      nTrigger = UNTimeIntervalNotificationTrigger(
        timeInterval: .leastNonzeroMagnitude,
        repeats: false
      )
    }

    let request = UNNotificationRequest(
      identifier: id,
      content: nContent,
      trigger: nTrigger
    )
    nCenter.add(request)
  }
}
