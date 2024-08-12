//
//  Store+OptionalScope.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 12.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

@_spi(Internals) import ComposableArchitecture

public extension Store {
  /// Scopes the store to optional child state and actions.
  ///
  /// If your feature holds onto a child feature as an optional:
  ///
  /// ```swift
  /// @Reducer
  /// struct Feature {
  ///   @ObservableState
  ///   struct State {
  ///     var child: Child.State?
  ///     // ...
  ///   }
  ///   enum Action {
  ///     case child(Child.Action)
  ///     // ...
  ///   }
  ///   // ...
  /// }
  /// ```
  ///
  /// …then you can use this `scope` operator in order to transform a store of your feature into
  /// a non-optional store of the child domain:
  ///
  /// ```swift
  /// if let childStore = store.scope(state: \.child, action: \.child) {
  ///   ChildView(store: childStore)
  /// }
  /// ```
  ///
  /// > Important: This operation should only be used from within a SwiftUI view or within
  /// > `withPerceptionTracking` in order for changes of the optional state to be properly
  /// > observed.
  ///
  /// - Parameters:
  ///   - state: A key path to optional child state.
  ///   - action: A case key path to child actions.
  /// - Returns: An optional store of non-optional child state and actions.
  func optionalScope<ChildState, ChildAction>(
    state: KeyPath<State, ChildState?>,
    action: CaseKeyPath<Action, ChildAction>
  ) -> Store<ChildState, ChildAction>? {
    guard var childState = self.currentState[keyPath: state]
    else { return nil }
    return self.scope(
      id: self.id(state: state.appending(path: \.!), action: action),
      state: ToState {
        childState = $0[keyPath: state] ?? childState
        return childState
      },
      action: { action($0) },
      isInvalid: { $0[keyPath: state] == nil }
    )
  }
}
