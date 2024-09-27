//
//  CodableStorage.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 01.09.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

protocol ICodableStorage {
  func store<T: Encodable>(_ value: T, key: String) throws
  func stored<T: Decodable>(type: T.Type, key: String) -> T?
}
