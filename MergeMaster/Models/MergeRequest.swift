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
    let title: String
    let author: User
    let webUrl: String
    let numberOfComments: Int
}

extension MergeRequest: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id, title, author
        case webUrl = "web_url"
        case numberOfComments = "user_notes_count"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(User.self, forKey: .author)
        webUrl = try container.decode(String.self, forKey: .webUrl)
        numberOfComments = try container.decodeIfPresent(Int.self, forKey: .numberOfComments) ?? 0
    }
    
}
