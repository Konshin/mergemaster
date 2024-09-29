//
//  NotificationContent.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 29.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

struct NotificationContent {
  var category: Category
  var title: String?
  var subtitle: String?
  var body: String?
  var userInfo: [AnyHashable: Any]?
}

extension NotificationContent {
  enum Category: String {
    case newRequests = "new_requests"
    case newComments = "new_comments"
  }
}
