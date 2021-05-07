//
//  MergeRequestInfo.swift
//  MergeMaster
//
//  Created by Aleksei Konshin on 06.05.2021.
//  Copyright © 2021 Konshin. All rights reserved.
//

import Foundation

struct MergeRequestInfo {
    let id: Int
    let title: String
    let author: User
    let webURL: String
    let numberOfComments: Int
    let approvedBy: [User]
}
