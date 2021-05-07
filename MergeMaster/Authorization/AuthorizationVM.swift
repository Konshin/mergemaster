//
//  AuthorizationVM.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

private enum AuthorizationError: Error {
    case wrongCredentials
}

final class AuthorizationVM {
    
    enum State: Equatable {
        case idle
        case processing
        case error(String)
    }
    
    let facade: AppFacade
    let appState: AppState
    let configuration: Configuration
    let router: Router
    
    let token = BehaviorRelay<String?>(value: nil)
    let url = BehaviorRelay<String?>(value: nil)
    private let state = BehaviorRelay<State>(value: .idle)
    
    private let disposeBag = DisposeBag()
    
    init(facade: AppFacade, appState: AppState, configuration: Configuration, router: Router) {
        self.appState = appState
        self.configuration = configuration
        self.router = router
        self.facade = facade
    }
    
    // MARK: - getters
    
    var authTitle: String {
        return "Authorization"
    }
    
    var loginEnabled: Observable<Bool> {
        let isTokenValid = token.map { $0?.isEmpty == false }
        let isURLValid = url.map { $0.flatMap(URL.init) != nil }
        let isNotInLoading = state.map { $0 != .processing }
        return Observable.combineLatest(isTokenValid, isURLValid, isNotInLoading) { $0 && $1 && $2 }
            .distinctUntilChanged()
    }
    
    var error: Observable<String?> {
        return state.map { state in
            switch state {
            case .error(let error):
                return error
            default:
                return nil
            }
        }
    }
    
    // MARK: - functions
    
    func setup() {
        token.accept(appState.privateToken.value)
        url.accept(configuration.serverUrl?.absoluteString)
    }
    
    func authorize() {
        facade.authorize(gitlabUrlString: url.value ?? "",
                         token: token.value ?? "")
            .observeOn(MainScheduler.instance)
            .do(onSubscribe: { [weak self] in
                self?.state.accept(.processing)
            })
            .subscribe { [weak self] event in
                switch event {
                case .success:
                    self?.state.accept(.idle)
                case .error(let error):
                    self?.state.accept(.error(error.localizedDescription))
                }
            }
            .disposed(by: disposeBag)
    }
    
    func exit() {
        router.exit()
    }
}
