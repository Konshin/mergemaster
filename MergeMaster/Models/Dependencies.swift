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

  private(set) lazy var menuWizard: IMenuWizard = makeMenuWizard()
  private(set) lazy var apiClient = makeApiClient()
  private(set) lazy var appFacade = makeAppFacade()
  private(set) lazy var filtersRepository: IFiltersRepository = makeFiltersRepository()
  private(set) lazy var projectsRepository: IProjectsRepository = makeProjectsRepository()
  private(set) lazy var selectedProjectsRepository: ISavedProjectsRepository = makeSavedProjectsRepository()
  private(set) lazy var requestsRepository: IRequestsRepository = makeRequestsRepository()
  private(set) lazy var defaultsStorage = makeDefaultsStorage()
  private(set) lazy var appStateManager = makeAppStateManager()
  private(set) lazy var notificationsManager = makeNotificationsManager()
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

  private func makeAppFacade() -> AuthorizationService {
    AuthorizationService(
      apiClient: apiClient,
      configuration: configuration,
      appState: appState,
      filtersRepository: filtersRepository,
      savedProjectsRepository: selectedProjectsRepository,
      requestsRepository: requestsRepository
    )
  }

  private func makeApiClient() -> ApiClient {
    ApiClient(
      configuration: configuration,
      appState: appState
    )
  }

  private func makeFiltersRepository() -> FiltersRepository {
    FiltersRepository(storage: defaultsStorage)
  }

  private func makeProjectsRepository() -> ProjectsRepository {
    ProjectsRepository(apiClient: apiClient, storage: defaultsStorage)
  }

  private func makeSavedProjectsRepository() -> SavedProjectsRepository {
    SavedProjectsRepository(store: defaultsStorage)
  }

  private func makeDefaultsStorage() -> DefaultsStorage {
    DefaultsStorage()
  }

  private func makeRequestsRepository() -> RequestsRepository {
    RequestsRepository(apiClient: apiClient, storage: defaultsStorage)
  }

  private func makeAppStateManager() -> AppStateManager {
    AppStateManager(
      requestsRepository: requestsRepository,
      filtersRepository: filtersRepository,
      menuWizard: menuWizard,
      notificationsManager: notificationsManager,
      savedProjectsRepository: selectedProjectsRepository
    )
  }

  private func makeNotificationsManager() -> NotificationsManager {
    NotificationsManager()
  }
}
