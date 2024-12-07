//
//  RequestsFilter.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 11.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct RequestsFilter: Equatable, Codable {
  var orExpressions: [Expression]

  var isEmpty: Bool {
    return orExpressions.allSatisfy {
      $0.conditions.isEmpty
    }
  }

  static var empty: RequestsFilter = RequestsFilter(orExpressions: [])
}

extension RequestsFilter {
  struct Expression: Equatable, Codable {
    var conditions: [Condition]
  }

  struct Condition: Equatable, Codable {
    var property: Property
    var `operator`: Operator = .equal
    var value: String
  }

  enum Property: String, Codable {
    case assignee, author, labels, reviewers
  }
}

extension RequestsFilter.Condition {
  enum Operator: String, Codable {
    case equal, notEqual, contains
  }
}
