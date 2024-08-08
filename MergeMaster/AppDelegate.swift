//
//  AppDelegate.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

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
      }
    }
    let view = Dependencies(menuRouter: menuRouter)
    return view
  }()

  private let disposeBag = DisposeBag()

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    NSUserNotificationCenter.default.delegate = self

    self.coordinator = Coordinator(dependencies: dependencies)

    dependencies.appState.isAuthorized.asDriver(onErrorJustReturn: false)
      .drive(onNext: { [weak self] authorized in
        if !authorized || self?.dependencies.configuration.serverUrl == nil {
          self?.coordinator.showAuthController()
        } else if self?.dependencies.appState.selectedProjects.value.isEmpty == false {
          self?.coordinator.showRequestsController()
        } else {
          self?.coordinator.showProjectsController()
        }
      })
      .disposed(by: disposeBag)

    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak coordinator] event in
      if coordinator?.isPopoverShown == true {
        coordinator?.dissmissPopover()
      }
    }
    eventMonitor?.start()
    _ = dependencies.menuWizard
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
    if let url = notification.userInfo?["URL"] as? String,
       let URL = URL(string: url)
    {
      NSWorkspace.shared.open(URL)
    } else if let button = dependencies.menuWizard.statusItem.button {
      coordinator?.showPopover(aroundButton: button)
    }
  }
}

