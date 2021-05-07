//
//  Approvals.swift
//  MergeMaster
//
//  Created by Aleksei Konshin on 06.05.2021.
//  Copyright © 2021 Konshin. All rights reserved.
//

import Foundation

struct Approvals {
    let id: Int
    let iid: Int
    let projectId: Int
    let title: String
    let mergeStatus: String
    let approvalsRequired: Int
    let approvalsLeft: Int
    let approvedBy: [ApprovedBy]
}

struct ApprovedBy: Decodable {
    let user: User
}

extension Approvals: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        case id, iid, title
        case projectId = "project_id"
        case mergeStatus = "merge_status"
        case approvalsRequired = "approvals_required"
        case approvalsLeft = "approvals_left"
        case approvedBy = "approved_by"
    }
    
}
