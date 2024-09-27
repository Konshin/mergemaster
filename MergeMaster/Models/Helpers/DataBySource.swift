//
//  DataBySource.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 26.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

@dynamicMemberLookup
enum DataBySource<T> {
  case cached(T)
  case fetched(T)

  var wrappedValue: T {
    switch self {
    case .cached(let value), .fetched(let value):
      return value
    }
  }

  subscript<V>(dynamicMember keyPath: KeyPath<T, V>) -> V {
    return wrappedValue[keyPath: keyPath]
  }
}
