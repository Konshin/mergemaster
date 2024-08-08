//
//  Approvals.swift
//  MergeMaster
//
//  Created by Aleksei Konshin on 06.05.2021.
//  Copyright © 2021 Konshin. All rights reserved.
//

import Foundation

struct Approvals {
  let approved: Bool
  let approvedBy: [ApprovedBy]
}

struct ApprovedBy: Decodable {
  let user: User
}

extension Approvals: Decodable {
  private enum CodingKeys: String, CodingKey {
    case approved
    case approvedBy = "approved_by"
  }
}
