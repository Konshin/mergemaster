//
//  MergeRequest.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation

struct MergeRequest: Equatable {
  let id: Int
  let iid: Int
  let title: String
  let author: User
  let reviewers: [User]
  let assignees: [User]
  let webUrl: String
  let numberOfComments: Int
}

extension MergeRequest: Codable {

  private enum CodingKeys: String, CodingKey {
    case id, title, author, iid, reviewers, assignees
    case webUrl = "web_url"
    case numberOfComments = "user_notes_count"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(Int.self, forKey: .id)
    iid = try container.decode(Int.self, forKey: .iid)
    title = try container.decode(String.self, forKey: .title)
    author = try container.decode(User.self, forKey: .author)
    webUrl = try container.decode(String.self, forKey: .webUrl)
    numberOfComments = try container.decodeIfPresent(Int.self, forKey: .numberOfComments) ?? 0
    assignees = try container.decode([User].self, forKey: .assignees)
    reviewers = try container.decode([User].self, forKey: .reviewers)
  }

}
