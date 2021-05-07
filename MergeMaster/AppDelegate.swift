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
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet weak var window: NSWindow!
    private let configuration = Configuration.saved
    private let appState = AppState.shared
    private lazy var facade = AppFacade(apiClient: apiClient,
                                        configuration: configuration,
                                        appState: appState)
    private lazy var apiClient: ApiClient = ApiClient(configuration: configuration, appState: appState)
    private var router: Router?
    private var menuWizard: MenuWizard!
    private var eventMonitor: EventMonitor?
    
    private let disposeBag = DisposeBag()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSUserNotificationCenter.default.delegate = self
        
        let router = Router(apiClient: apiClient, appState: appState, configuration: configuration, facade: facade)
        menuWizard = MenuWizard(statusBar: NSStatusBar.system, router: router, appState: appState)
        
        self.router = router
        
        appState.isAuthorized.asDriver(onErrorJustReturn: false)
            .drive(onNext: { [unowned self, configuration] authorized in
                if !authorized || configuration.serverUrl == nil {
                    router.showAuthController()
                } else if self.appState.selectedProjects.value.isEmpty == false {
                    router.showRequestsController()
                } else {
                    router.showProjectsController()
                }
            })
        .disposed(by: disposeBag)
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { event in
            if router.isPopoverShown {
                router.dissmissPopover()
            }
        }
        eventMonitor?.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if let url = notification.userInfo?["URL"] as? String,
            let URL = URL(string: url)
        {
            NSWorkspace.shared.open(URL)
        } else {
            router?.showPopover(aroundButton: menuWizard.statusItem.button!)
        }
    }
}

