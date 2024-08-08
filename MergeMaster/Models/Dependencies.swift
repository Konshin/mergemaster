//
//  Dependencies.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import Cocoa

final class Dependencies {
  private let menuRouter: Router<MenuWizard.Route>

  private(set) lazy var menuWizard = makeMenuWizard()
  private(set) lazy var apiClient = makeApiClient()
  private(set) lazy var appFacade = makeAppFacade()
  let configuration = Configuration.saved
  let appState = AppState.shared

  init(menuRouter: Router<MenuWizard.Route>) {
    self.menuRouter = menuRouter
  }
}

// MARK: - Assembly
extension Dependencies {
  private func makeMenuWizard() -> MenuWizard {
    MenuWizard(
      statusBar: NSStatusBar.system,
      router: menuRouter,
      appState: appState
    )
  }

  private func makeAppFacade() -> AppFacade {
    AppFacade(
      apiClient: apiClient,
      configuration: configuration,
      appState: appState
    )
  }

  private func makeApiClient() -> ApiClient {
    ApiClient(
      configuration: configuration,
      appState: appState
    )
  }
}
