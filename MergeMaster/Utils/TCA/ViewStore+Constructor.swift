//
//  ViewStore+COnstructor.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import ComposableArchitecture

extension ViewStore {
  static func preview<R: Reducer<ViewState, ViewAction>>(
    state: ViewState,
    @ReducerBuilder<ViewState, ViewAction> reducer: () -> R
  ) -> ViewStore<ViewState, ViewAction> where ViewState: Equatable {
    let store = Store<ViewState, ViewAction>(
      initialState: state,
      reducer: reducer
    )
    return ViewStore<ViewState, ViewAction>(store, observe: { $0 })
  }

  static func adapted<State, Action, R: Reducer, A: ViewAdapter>(
    state: State,
    @ReducerBuilder<State, Action>
    reducer: () -> R,
    adapter: A
  ) -> ViewStore<ViewState, ViewAction>
    where R.Action == Action,
            R.State == State,
          A.Action == Action,
          A.State == State,
          A.ViewAction == ViewAction,
          A.ViewState == ViewState,
          ViewState: Equatable
  {
    let store = Store<State, Action>(initialState: state, reducer: reducer)
    return ViewStore(
      store,
      observe: adapter.adapt(state:),
      send: adapter.adapt(action:)
    )
  }
}
