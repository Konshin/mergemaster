//
//  DefaultsStorage.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 01.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

final class DefaultsStorage {
  private let defaults = UserDefaults.standard
  private let decoder = JSONDecoder()
  private let encoder = JSONEncoder()
}

extension DefaultsStorage: ICodableStorage {
  func stored<T>(type: T.Type, key: String) -> T? where T : Decodable {
    guard let data = defaults.data(forKey: key) else { return nil }
    return try? decoder.decode(type, from: data)
  }

  func store<T>(_ value: T, key: String) throws where T : Encodable {
    let data = try encoder.encode(value)
    defaults.set(data, forKey: key)
  }
}
