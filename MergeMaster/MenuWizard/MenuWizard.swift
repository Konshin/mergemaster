//
//  MenuWizard.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import Foundation

protocol IMenuWizard {
  var statusItem: NSStatusItem { get }
  func setNumberOfRequests(_ num: Int)
}

final class MenuWizard: NSObject {
  private let router: Router<Route>
  private let appState: AppState
  /// Инстанс статус бара osx
  private let statusBar: NSStatusBar
  /// Инстанс итема приложения в баре osx
  let statusItem: NSStatusItem
  private var imageCache: [NSColor: NSImage] = [:]

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
      button.action = #selector(self.clickToItem)
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
      button.menu = self.makeMennu()
    }

    setNumberOfRequests(0)
  }

  @objc func clickToItem(button: NSStatusBarButton) {
    switch NSApp.currentEvent?.type {
    case .leftMouseUp:
      togglePopover(button: button)
    case .rightMouseUp:
      button.menu?.popUp(positioning: nil, at: .zero, in: button)
    default:
      break
    }
  }

  private func togglePopover(button: NSStatusBarButton) {
    router.syncTrigger(.togglePopoverVisibility(sender: button))
  }

  @objc
  private func logout() {
    router.syncTrigger(.logout)
  }

  @objc
  private func quit() {
    router.syncTrigger(.quit)
  }

  @objc
  private func selectProjects() {
    router.syncTrigger(.selectProjects)
  }
}

extension MenuWizard: IMenuWizard {
  /// Отображает количество реквестов на статус баре
  func setNumberOfRequests(_ num: Int) {
    let color = num > 0 ? NSColor.controlAccentColor : NSColor.labelColor
    let title = NSAttributedString(
      string: "\(num)",
      attributes: [
        NSAttributedString.Key.foregroundColor: color,
        .font: NSFont.systemFont(ofSize: 13, weight: .medium)
      ]
    )

    let button = statusItem.button
    button?.attributedTitle = title
    button?.image = self.image(color: color)
  }

  private func image(color: NSColor) -> NSImage? {
    if let cached = imageCache[color] {
      return cached
    } else {
      guard let image = NSImage(named: "mr_status_icon_16") else { return nil }
      image.isTemplate = false
      image.lockFocus()

      color.set()

      let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
      imageRect.fill(using: .sourceAtop)

      image.unlockFocus()
      imageCache[color] = image

      return image
    }
  }
}

// MARK: - Nested types and constructors
extension MenuWizard {
  enum Route {
    case togglePopoverVisibility(sender: NSStatusBarButton)
    case selectProjects
    case logout
    case quit
  }

  private func makeMennu() -> NSMenu {
    let menu = NSMenu()

    menu.addItem(
      withTitle: "Select projects",
      action: #selector(selectProjects),
      keyEquivalent: ""
    ).target = self
    menu.addItem(.separator())
    menu.addItem(
      withTitle: "Logout",
      action: #selector(logout),
      keyEquivalent: ""
    ).target = self

    menu.addItem(
      withTitle: "Quit",
      action: #selector(quit),
      keyEquivalent: ""
    ).target = self
    return menu
  }
}
