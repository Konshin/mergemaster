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
    
    let apiClient: ApiClient
    let appState: AppState
    let configuration: Configuration
    let router: Router
    
    let token = BehaviorRelay<String?>(value: nil)
    let url = BehaviorRelay<String?>(value: nil)
    private let state = BehaviorRelay<State>(value: .idle)
    
    private let disposeBag = DisposeBag()
    
    init(apiClient: ApiClient, appState: AppState, configuration: Configuration, router: Router) {
        self.apiClient = apiClient
        self.appState = appState
        self.configuration = configuration
        self.router = router
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
        let url = self.url
        let token = self.token
        let prepareURL = Single<Token>.create { [configuration] observer in
            var url: URL? {
                guard let urlStirng = url.value, var components = URLComponents(string: urlStirng) else { return nil }
                if !components.path.isEmpty && components.host == nil {
                    components.host = components.path
                    components.path = ""
                }
                if components.scheme == nil {
                    components.scheme = "https"
                }
                return components.url
            }
            if let token = token.value, let gitlabURL = url {
                configuration.update(serverUrl: gitlabURL)
                observer(.success(token))
            } else {
                observer(.error(AuthorizationError.wrongCredentials))
            }
            return Disposables.create()
        }
        prepareURL.flatMap { [apiClient] token in
            apiClient.getProjects(token: token)
                .map { _ in token }
        }
        .observeOn(MainScheduler.instance)
        .do(onSubscribe: { [weak self] in
            self?.state.accept(.processing)
        })
        .subscribe { [appState, configuration, weak self] event in
            switch event {
            case .success(let token):
                configuration.saveToCache()
                appState.privateToken.accept(token)
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
