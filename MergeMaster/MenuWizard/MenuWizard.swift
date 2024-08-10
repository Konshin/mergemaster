//
//  MenuWizard.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import RxSwift

final class MenuWizard: NSObject {
  private let router: Router<Route>
  private let appState: AppState
  /// Инстанс статус бара osx
  private let statusBar: NSStatusBar
  /// Инстанс итема приложения в баре osx
  let statusItem: NSStatusItem

  private let disposeBag = DisposeBag()

  init(statusBar: NSStatusBar, router: Router<Route>, appState: AppState) {
    self.statusBar = statusBar
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
    self.router = router
    self.appState = appState

    super.init()

    initialize()
  }

  //MARK: - Actions

  private func initialize() {
    if let button = statusItem.button {
      button.target = self
      button.action = #selector(tapToItem(button:))
    }

    setNumberOfRequests(appState.numberOfRequests.value)

    appState.numberOfRequests
      .asDriver()
      .drive(onNext: { [unowned self] num in
        self.setNumberOfRequests(num)
      })
      .disposed(by: disposeBag)
  }

  @objc func tapToItem(button: NSStatusBarButton) {
    togglePopover(button: button)
  }

  func togglePopover(button: NSStatusBarButton) {
    router.syncTrigger(.togglePopoverVisibility(sender: button))
//    if router.isPopoverShown {
//      router.dissmissPopover()
//    } else {
//      router.showPopover(aroundButton: button)
//    }
  }
  /// Отображает количество реквестов на статус баре
  private func setNumberOfRequests(_ num: Int) {
    let title = NSAttributedString(
      string: "mr: \(num)",
      attributes: [
        NSAttributedString.Key.foregroundColor: num == 0 ? NSColor.labelColor : NSColor.controlAccentColor
      ]
    )
    statusItem.attributedTitle = title
  }
}

extension MenuWizard {
  enum Route {
    case togglePopoverVisibility(sender: NSStatusBarButton)
  }
}
