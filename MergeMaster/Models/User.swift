//
//  User.swift
//  MergeMaster
//
//  Created by Konshin on 19.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation

struct User: Equatable {
    let name: String
    let avatarUrl: String
}

extension User: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case name
        case avatarUrl = "avatar_url"
    }
    
}
