//
//  AppState.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

private struct Constants {
    static let tokenCacheKey = "PRIVATE_TOKEN"
    static let projectsCacheKey = "PROJECT_IDS"
    static let loginCacheKey = "USER_LOGIN"
}

typealias Token = String

struct AppState {
    /// Current API token
    let privateToken: BehaviorRelay<Token?>
    /// Ids for selected projects
    let selectedProjects: BehaviorRelay<[ProjectId]>
    /// Number of actual requests
    let numberOfRequests = BehaviorRelay(value: 0)
    
    private let disposeBag = DisposeBag()
    
    /// Идентификация, авторизованы ли мы
    var isAuthorized: Observable<Bool> {
        return privateToken.map { $0 != nil }
    }
    
    var isAuthorizedValue: Bool {
        return privateToken.value != nil
    }
    
    static let shared = AppState()
    
    private init() {
        let defaults = UserDefaults.standard
        let cachedToken = defaults.object(forKey: Constants.tokenCacheKey) as? Token
        let cachedProjectsIds = defaults.object(forKey: Constants.projectsCacheKey) as? [ProjectId]
        privateToken = BehaviorRelay(value: cachedToken)
        selectedProjects = BehaviorRelay(value: cachedProjectsIds ?? [])
        
        initialize()
    }
    
    private func initialize() {
        privateToken.asObservable()
            .subscribe(onNext: { token in
                UserDefaults.standard.set(token, forKey: Constants.tokenCacheKey)
            })
            .disposed(by: disposeBag)
        
        selectedProjects.asObservable()
            .subscribe(onNext: { projects in
                UserDefaults.standard.set(projects, forKey: Constants.projectsCacheKey)
            })
            .disposed(by: disposeBag)
    }
}
