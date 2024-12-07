//
//  MenuWizard.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa

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
      button.action = #selector(tapToItem(button:))
    }

    setNumberOfRequests(0)
  }

  @objc func tapToItem(button: NSStatusBarButton) {
    togglePopover(button: button)
  }

  func togglePopover(button: NSStatusBarButton) {
    router.syncTrigger(.togglePopoverVisibility(sender: button))
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

extension MenuWizard {
  enum Route {
    case togglePopoverVisibility(sender: NSStatusBarButton)
  }
}
