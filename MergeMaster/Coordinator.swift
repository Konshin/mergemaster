//
//  Router.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import SwiftUI

final class Coordinator: NSObject {
  private(set) var currentController: NSViewController!
  fileprivate let popover = NSPopover()

  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies

    super.init()

    popover.delegate = self
  }

  //MARK: - Getters

  private var authController: AuthorizationController {
    let vm = AuthorizationVM(
      facade: dependencies.appFacade,
      appState: dependencies.appState,
      configuration: dependencies.configuration,
      router: self
    )
    return AuthorizationController(viewModel: vm)
  }

  var isPopoverShown: Bool {
    return popover.isShown
  }

  //MARK: - Actions

  func showAuthController() {
    guard !(currentController is AuthorizationController) else {
      // Auth controller is already displayed
      return
    }

    showController(vc: authController)
  }

  func showProjectsController() {
    let assembly = ProjectsListAssembly(dependencies: dependencies)
    let router = Router<ProjectsListReducer.Route>.weak(object: self) { c, r in
      switch r {
      case .confirm:
        c.showRequestsController()
        c.askNotificationPermissionIfNeeded()
      }
    }
    let view = assembly.makeView(router: router)
    let vc = NSHostingController(rootView: view)
    if #available(macOS 13.0, *) {
      vc.sizingOptions = .preferredContentSize
    } else {
      // Fallback on earlier versions
    }
    showController(vc: vc)
  }

  func showRequestsController() {
    let assembly = RequestsListAssembly(dependencies: dependencies)
    let router = Router<RequestsListReducer.Route>.weak(object: self) { c, r in
      switch r {
      case .settings:
        break
      case .changeProjects:
        c.showProjectsController()
      case .logout:
        c.dependencies.appFacade.logout()
      case .exit:
        c.exit()
      case .openProject(let url):
        NSWorkspace.shared.open(url)
      case .openRequest(let url):
        NSWorkspace.shared.open(url)
      }
    }
    let view = assembly.makeView(router: router)
    let vc = NSHostingController(rootView: view)
    if #available(macOS 13.0, *) {
      vc.sizingOptions = .preferredContentSize
    } else {
      // Fallback on earlier versions
    }
    showController(vc: vc)
  }

  func showPopover(aroundButton button: NSStatusBarButton) {
    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
  }

  func dissmissPopover() {
    popover.performClose(nil)
  }

  /// Close the app
  func exit() {
    NSApplication.shared.terminate(self)
  }

  // MARK: - Private

  private func showController(vc: NSViewController) {
    currentController = vc
    popover.contentViewController = vc
  }

  private func askNotificationPermissionIfNeeded() {
    Task {
      await dependencies.notificationsManager.authorizeIfNeeded()
    }
  }
}


extension Coordinator: NSPopoverDelegate {
  func popoverWillShow(_ notification: Notification) {
    popover.contentSize = currentController.preferredContentSize
  }
}
