//
//  AppState.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import Combine

private struct Constants {
  static let tokenCacheKey = "PRIVATE_TOKEN"
}

typealias Token = String

final class AppState {
  /// Current API token
  let privateToken: CurrentValueSubject<Token?, Never>

  private var binding: AnyCancellable?

  /// Идентификация, авторизованы ли мы
  var isAuthorized: AnyPublisher<Bool, Never> {
    return privateToken.map { $0 != nil }
      .eraseToAnyPublisher()
  }

  var isAuthorizedValue: Bool {
    return privateToken.value != nil
  }


  static let shared = AppState()

  private init() {
    let cachedToken = UserDefaults.standard.object(forKey: Constants.tokenCacheKey) as? Token
    privateToken = CurrentValueSubject(cachedToken)

    initialize()
  }

  private func initialize() {
    binding = privateToken
      .dropFirst()
      .sink(receiveValue: { token in
        UserDefaults.standard.set(token, forKey: Constants.tokenCacheKey)
      })
  }
}
