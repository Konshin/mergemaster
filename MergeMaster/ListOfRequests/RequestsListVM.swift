//
//  RequestsListVM.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

private struct Constants {
    static let updateInterval: Int = 30
}

final class RequestsListVM {
    
    enum Item {
        case cell(RequestCellViewModel)
        case header(Header)
    }
    
    struct Header {
        let title: String
        let tapHandler: () -> Void
    }
    
    private let router: Router
    private let facade: AppFacade
    private let appState: AppState
    
    private var disposeBag: DisposeBag = DisposeBag()
    
    private var projectRequests: [AppFacade.ProjectRequests] = []
    private let itemsRelay = BehaviorRelay<[Item]>(value: [])
    
    init(router: Router, facade: AppFacade, appState: AppState) {
        self.router = router
        self.facade = facade
        self.appState = appState
        
        initialize()
    }
    
    //MARK: - Getters
    
    var items: [Item] {
        return itemsRelay.value
    }
    
    var updateSignal: Observable<()> {
        return itemsRelay.map { _ in () }
    }
    
    var selectProjectsTitle: Driver<String> {
        return appState.selectedProjects.asDriver()
            .map() { projects in
                return "Projects selected: \(projects.count)"
        }
    }
    
    //MARK: - private functions
    
    private func initialize() {
        updateRequests(notifyAboutDiff: false)
        initializeHooks()
    }
    
    private func initializeHooks() {
        Observable<Int>.interval(.seconds(Constants.updateInterval), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.updateRequests(notifyAboutDiff: true)
            })
        .disposed(by: disposeBag)
    }
    
    private func updateRequests(notifyAboutDiff: Bool) {
        let requestsBefore = projectRequests.reduce([MergeRequestInfo]()) { $0 + $1.requests }
        
        facade.requestsInfo()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] requests in
                self?.setProjectRequests(requests)
                if notifyAboutDiff {
                    let requests = requests.reduce([MergeRequestInfo]()) { $0 + $1.requests }
                    self?.notifyAboutDiffIfNeeded(oldRequests: requestsBefore, requests: requests)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setProjectRequests(_ requests: [AppFacade.ProjectRequests]) {
        projectRequests = requests
        let items: [Item] = requests.reduce(into: []) { (result, requests) in
            let header = Header(title: requests.project.name) { [weak self] in
                self?.openStringURL(requests.project.webUrl)
            }
            result.append(.header(header))
            requests.requests.forEach { request in
                let item = RequestCellViewModel(
                    name: request.title,
                    url: request.webURL,
                    userAvatarUrl: request.author.avatarUrl,
                    userName: request.author.name,
                    approvedBy: request.approvedBy.map { $0.name }
                )
                result.append(.cell(item))
            }
        }
        itemsRelay.accept(items)
    }
    
    private func openStringURL(_ stringURL: String) {
        guard let url = URL(string: stringURL) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
    
    private func notifyAboutDiffIfNeeded(oldRequests: [MergeRequestInfo], requests: [MergeRequestInfo]) {
        notifyAboutNewRequestsIfNeeded(oldRequests: oldRequests, requests: requests)
        notifyAboutNewCommentsIfNeeded(oldRequests: oldRequests, requests: requests)
        notifyAboutNewApprovalsIfNeeded(oldRequests: oldRequests, requests: requests)
    }
    
    private func notifyAboutNewRequestsIfNeeded(oldRequests: [MergeRequestInfo], requests: [MergeRequestInfo]) {
        if requests.count > oldRequests.count {
            let numberOfNewRequests = requests.count - oldRequests.count
            
            let n = NSUserNotification()
            if numberOfNewRequests == 1 {
                n.title = "1 new Merge Request"
            } else {
                n.title = "\(numberOfNewRequests) new Merge Requests"
            }
            
            if let newRequest = requests.first(where: { new in !oldRequests.contains(where: { $0.id == new.id }) }) {
                // Если всего 1 новый реквест - даем на него ссылку
                n.userInfo = ["URL": newRequest.webURL]
            }
            
            n.identifier = "new_request"
            n.deliveryDate = Date()
            
            NSUserNotificationCenter.default.scheduleNotification(n)
        }
    }
    
    private func notifyAboutNewCommentsIfNeeded(oldRequests: [MergeRequestInfo], requests: [MergeRequestInfo]) {
        let commentsBefore = oldRequests.reduce(into: [Int: Int]()) { (result, request) in
            result[request.id] = request.numberOfComments
        }
        let commentsAfter = requests.reduce(into: [Int: Int]()) { (result, request) in
            result[request.id] = request.numberOfComments
        }
        var newComments = 0
        let requestsWithNewComments = requests.filter { request in
            let before = commentsBefore[request.id] ?? 0
            let after = commentsAfter[request.id] ?? 0
            let new = after - before
            let hasNew = new > 0
            if hasNew {
                newComments += new
            }
            return hasNew
        }
        guard !requestsWithNewComments.isEmpty else { return }
        
        let n = NSUserNotification()
        if requestsWithNewComments.count == 1 {
            let request = requestsWithNewComments[0]
            n.title = "1 new comment"
            n.subtitle = request.title
            n.userInfo = ["URL": request.webURL]
        } else {
            let titles = requestsWithNewComments.map { $0.title }.joined(separator: ", ")
            n.title = "\(newComments) new comments"
            n.subtitle = titles
        }
        
        n.identifier = "new_comments"
        n.deliveryDate = Date()
        
        NSUserNotificationCenter.default.scheduleNotification(n)
    }
    
    private func notifyAboutNewApprovalsIfNeeded(oldRequests: [MergeRequestInfo], requests: [MergeRequestInfo]) {
        let approversBefore = oldRequests.reduce(into: [Int: [User]]()) { (result, request) in
            result[request.id] = request.approvedBy
        }
        let approversAfter = requests.reduce(into: [Int: [User]]()) { (result, request) in
            result[request.id] = request.approvedBy
        }
        var newApprovers = 0
        let requestsWithNewApprovs = requests.filter { request in
            let before = approversBefore[request.id] ?? []
            let after = approversAfter[request.id] ?? []
            let new = after.count - before.count
            let hasNew = new > 0
            if hasNew {
                newApprovers += new
            }
            return hasNew
        }
        guard !requestsWithNewApprovs.isEmpty else { return }
        
        let n = NSUserNotification()
        if requestsWithNewApprovs.count == 1 {
            let request = requestsWithNewApprovs[0]
            n.title = "Got Approve for request"
            n.subtitle = request.title
            n.userInfo = ["URL": request.webURL]
        } else {
            let titles = requestsWithNewApprovs.map { $0.title }.joined(separator: ", ")
            n.title = "Got Approve for requests"
            n.subtitle = titles
        }
        
        n.identifier = "new_approvals"
        n.deliveryDate = Date()
        
        NSUserNotificationCenter.default.scheduleNotification(n)
    }
    
    // MARK: - functions
    
    /// Прекращает слежку за реквестами
    func stopUpdates() {
        disposeBag = DisposeBag()
    }
    
    func handleTap(index: Int) {
        router.dissmissPopover()
        switch items[index] {
        case .cell(let item):
            openStringURL(item.url)
        case .header(let header):
            header.tapHandler()
        }
    }
    
    func reselectProjects() {
        router.showProjectsController()
    }
    
    func logout() {
        appState.privateToken.accept(nil)
    }
    
    func exit() {
        router.exit()
    }
    
}
