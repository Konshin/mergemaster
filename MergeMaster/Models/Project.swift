//
//  Project.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation

typealias ProjectId = Int

struct Project {
    let id: ProjectId
    let name: String
    let webUrl: String
    var namespace: Namespace?
}

extension Project: Equatable {
    
    struct Namespace: Codable, Equatable {
        var name: String
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
}

extension Project: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case id, name, namespace
        case webUrl = "web_url"
    }
    
}
