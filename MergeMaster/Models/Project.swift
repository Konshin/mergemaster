//
//  Project.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation
import EZJson

typealias ProjectId = Int

struct Project {
    let id: ProjectId
    let name: String
    let webUrl: String
}

extension Project: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id, name
        case webUrl = "web_url"
    }
    
}
