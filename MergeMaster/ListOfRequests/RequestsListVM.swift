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

class RequestsListVM {
    private let router: Router
    private let appState: AppState
    private let apiClient: ApiClient
    
    private var disposeBag: DisposeBag! = DisposeBag()
    
    let requests = BehaviorRelay<[MergeRequest]>(value: [])
    
    init(router: Router, appState: AppState, apiClient: ApiClient) {
        self.router = router
        self.appState = appState
        self.apiClient = apiClient
        
        initialize()
    }
    
    //MARK: - Getters
    
    var numberOfRequests: Int {
        return requests.value.count
    }
    
    func cellVMAtIndex(index: Int) -> RequestCellViewModel {
        let request = requests.value[index]
        let viewModel = RequestCellViewModel(
            name: request.title,
            url: request.webUrl,
            userAvatarUrl: request.author.avatarUrl,
            userName: request.author.name
        )
        return viewModel
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
        guard let token = appState.privateToken.value else {
            print("Couldn't update requests: Token is invalid")
            return
        }
        
        let requestsBefore = requests.value
        
        let observers = appState.selectedProjects.value.map() { projectId in
            return apiClient.getRequests(projectId: projectId, token: token)
        }
        
        let updateObserver = Single.zip(observers) { values in
            return values.reduce([]) { acc, requests in
                return acc + requests
            }
        }
        
        updateObserver
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { requests in
                if notifyAboutDiff {
                    self.notifyAboutDiffIfNeeded(oldRequests: requestsBefore, requests: requests)
                }
                
                self.appState.numberOfRequests.accept(requests.count)
                self.requests.accept(requests) 
            })
            .disposed(by: disposeBag)
    }
    
    private func notifyAboutDiffIfNeeded(oldRequests: [MergeRequest], requests: [MergeRequest]) {
        if requests.count > oldRequests.count {
            let numberOfNewRequests = requests.count - oldRequests.count
            let n = NSUserNotification()
            n.title = "Found new Merge Requests: \(numberOfNewRequests)"
            
            if let newRequest = requests.first(where: { new in !oldRequests.contains(where: { $0.id == new.id }) }) {
                // Если всего 1 новый реквест - даем на него ссылку
                n.userInfo = ["URL": newRequest.webUrl]
            }
            
            n.deliveryDate = Date()
            
            NSUserNotificationCenter.default.scheduleNotification(n)
        } else {
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
                n.title = "New comments for request: \(request.title) (\(newComments))"
                n.userInfo = ["URL": request.webUrl]
            } else {
                let titles = requestsWithNewComments.map { $0.title }.joined(separator: ", ")
                n.title = "New comments for requests: [\(titles)] (\(newComments))"
            }
            
            n.deliveryDate = Date()
            
            NSUserNotificationCenter.default.scheduleNotification(n)
        }
    }
    
    // MARK: - functions
    
    /// Прекращает слежку за реквестами
    func stopUpdates() {
        disposeBag = nil
    }
    
    func tapToIndex(index: Int) {
        router.dissmissPopover()
        let viewModel = cellVMAtIndex(index: index)
        
        guard let url = URL(string: viewModel.url) else {
            return
        }
        NSWorkspace.shared.open(url)
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
