//
//  ViewAdapter.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

protocol ViewAdapter {
  associatedtype State
  associatedtype Action
  associatedtype ViewState
  associatedtype ViewAction

  func adapt(state: State) -> ViewState
  func adapt(action: ViewAction) -> Action
}
