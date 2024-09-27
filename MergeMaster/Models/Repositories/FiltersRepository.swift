//
//  FiltersRepository.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 26.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

protocol IFiltersRepository {
  typealias Filters = [ProjectId: RequestsFilter]
  var savedFilters: Filters { get }
  func update(filters: Filters)
}

final class FiltersRepository {

  private enum StorageKeys: String {
    case filters = "saved_request_filters"
  }

  private let storage: ICodableStorage
  private var filters: Filters

  init(
    storage: ICodableStorage
  ) {
    self.storage = storage

    let filters = storage.stored(type: Filters.self, key: StorageKeys.filters.rawValue)
    self.filters = filters ?? [:]
  }
}

extension FiltersRepository: IFiltersRepository {
  var savedFilters: Filters {
    filters
  }

  func update(filters: Filters) {
    self.filters = filters
    do {
      try storage.store(filters, key: StorageKeys.filters.rawValue)
    } catch {
      print("[ERROR] Failed to store filters: \(error)")
    }
  }
}

