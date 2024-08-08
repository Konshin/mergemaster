//
//  Router.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 06.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Foundation

struct Router<Route> {
  private let handler: (Route) -> Void

  @MainActor
  func trigger(_ route: Route) {
    _trigger(route: route)
  }

  @available(*, noasync)
  func syncTrigger(_ route: Route) {
    _trigger(route: route)
  }

  private func _trigger(route: Route) {
    handler(route)
  }
}

extension Router {
  static func weak<Object: AnyObject>(object: Object, handler: @escaping (Object, Route) -> Void) -> Router<Route> {
    return Router { [weak object] route in
      guard let object else { return }
      handler(object, route)
    }
  }
}
