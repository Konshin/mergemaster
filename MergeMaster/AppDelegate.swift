//
//  AppDelegate.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import Combine
import UserNotifications

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  private var coordinator: Coordinator!
  private var eventMonitor: EventMonitor?
  private lazy var dependencies: Dependencies = {
    let menuRouter = Router<MenuWizard.Route>.weak(object: self) { appDelegate, route in
      switch route {
      case .togglePopoverVisibility(let sender):
        guard let coordinator = appDelegate.coordinator else { return }
        if coordinator.isPopoverShown {
          coordinator.dissmissPopover()
        } else {
          coordinator.showPopover(aroundButton: sender)
        }
      case .logout:
        appDelegate.dependencies.appFacade.logout()
      case .quit:
        appDelegate.coordinator?.exit()
      case .selectProjects:
        appDelegate.coordinator?.showProjectsController(forceDisplay: true)
      }
    }
    let view = Dependencies(menuRouter: menuRouter)
    return view
  }()

  private var bindings = Set<AnyCancellable>()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    initializeServices()

    self.coordinator = Coordinator(
      dependencies: dependencies,
      requestToShowPopover: { [weak self] coordinator in
        guard let button = self?.dependencies.menuWizard.statusItem.button else { return }
        coordinator.showPopover(aroundButton: button)
      }
    )
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  private func initializeServices() {
    dependencies.appState.isAuthorized
      .receive(on: DispatchQueue.main)
      .sink { [weak self] authorized in
        if !authorized || self?.dependencies.configuration.serverUrl == nil {
          self?.coordinator.showAuthController()
        } else if self?.dependencies.selectedProjectsRepository.savedProjects.isEmpty == false {
          self?.coordinator.showRequestsController(forceDisplay: false)
        } else {
          self?.coordinator.showProjectsController(forceDisplay: false)
        }
      }
      .store(in: &bindings)

    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
      if self?.coordinator?.isPopoverShown == true {
        self?.coordinator?.dissmissPopover()
      }
    }
    eventMonitor?.start()
    // Start app state manager
    _ = dependencies.appStateManager

    Task {
      try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .provisional, .sound])
    }
  }
}

