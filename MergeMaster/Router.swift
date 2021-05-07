//
//  Router.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa

class Router: NSObject {
    var currentController: NSViewController!
    fileprivate let popover = NSPopover()
    
    private let apiClient: ApiClient
    private let appState: AppState
    private let configuration: Configuration
    private let facade: AppFacade
    
    init(apiClient: ApiClient, appState: AppState, configuration: Configuration, facade: AppFacade) {
        self.apiClient = apiClient
        self.appState = appState
        self.configuration = configuration
        self.facade = facade
        
        super.init()
        
        popover.delegate = self
    }
    
    //MARK: - Getters
    
    private var authController: AuthorizationController {
        let vm = AuthorizationVM(facade: facade, appState: appState, configuration: configuration, router: self)
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
        let viewModel = ProjectsListVM(router: self, appState: appState, facade: facade)
        let vc = ProjectsListController(viewModel: viewModel)
        showController(vc: vc)
    }
    
    func showRequestsController() {
        let viewModel = RequestsListVM(router: self, facade: facade, appState: appState)
        let vc = RequestsListController(viewModel: viewModel)
        showController(vc: vc)
    }
    
    func showPopover(aroundButton button: NSStatusBarButton) {
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
    }
    
    func dissmissPopover() {
        popover.performClose(nil)
    }
    
    private func showController(vc: NSViewController) {
        currentController = vc
        popover.contentViewController = vc
    }
    /// Close the app
    func exit() {
        NSApplication.shared.terminate(self)
    }
}


extension Router: NSPopoverDelegate {
    func popoverWillShow(_ notification: Notification) {
        popover.contentSize = currentController.preferredContentSize
    }
}
