//
//  TimeBasedData.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 14.01.2025.
//  Copyright © 2025 Konshin. All rights reserved.
//
import Foundation

struct TimeBasedData<T> {
  var time: Date
  var data: T
}

extension TimeBasedData: Equatable where T: Equatable {}
extension TimeBasedData: Decodable where T: Decodable {}
extension TimeBasedData: Encodable where T: Encodable {}

extension TimeBasedData {
  func map<U>(_ map: (T) -> U) -> TimeBasedData<U> {
    TimeBasedData<U>(
      time: time,
      data: map(data)
    )
  }
}
