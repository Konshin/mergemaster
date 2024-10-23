//
//  AuthorizationVM.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import Combine

private enum AuthorizationError: Error {
  case wrongCredentials
}

final class AuthorizationVM {

  enum State: Equatable {
    case idle
    case processing
    case error(String)
  }

  let facade: AuthorizationService
  let appState: AppState
  let configuration: Configuration
  let router: Coordinator

  let token = CurrentValueSubject<String?, Never>(nil)
  let url = CurrentValueSubject<String?, Never>(nil)
  private let state = CurrentValueSubject<State, Never>(.idle)

  private var bindings = Set<AnyCancellable>()

  init(facade: AuthorizationService, appState: AppState, configuration: Configuration, router: Coordinator) {
    self.appState = appState
    self.configuration = configuration
    self.router = router
    self.facade = facade
  }

  // MARK: - getters

  var authTitle: String {
    return "Authorization"
  }

  var loginEnabled: AnyPublisher<Bool, Never> {
    let isTokenValid = token.map { $0?.isEmpty == false }
    let isURLValid = url.map { $0.flatMap(URL.init) != nil }
    let isNotInLoading = state.map { $0 != .processing }
    return Publishers.CombineLatest3(isTokenValid, isURLValid, isNotInLoading)
      .map { $0 && $1 && $2 }
      .removeDuplicates()
      .eraseToAnyPublisher()
  }

  var error: AnyPublisher<String?, Never> {
    return state.map { state in
      switch state {
      case .error(let error):
        return error
      default:
        return nil
      }
    }
    .eraseToAnyPublisher()
  }

  // MARK: - functions

  func setup() {
    token.send(appState.privateToken.value)
    url.send(configuration.serverUrl?.absoluteString)
  }

  func authorize() {
    state.send(.processing)
    Task {
      do {
        try await facade.authorize(
          gitlabUrlString: url.value ?? "",
          token: token.value ?? ""
        )
        await MainActor.run {
          state.send(.idle)
        }
      } catch {
        await MainActor.run {
          state.send(.error(error.localizedDescription))
        }
      }
    }
  }

  func exit() {
    router.exit()
  }
}
