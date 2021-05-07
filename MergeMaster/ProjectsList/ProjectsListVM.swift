//
//  ProjectsListVM.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

final class ProjectsListVM {
    private let router: Router
    private let appState: AppState
    private let facade: AppFacade
    
    private let disposeBag = DisposeBag()
    private var cellViewModels = [Int: ProjectCellViewModel]()
    
    let projects = BehaviorRelay<[Project]>(value: [])
    let status = BehaviorRelay<String?>(value: nil)
    
    init(router: Router, appState: AppState, facade: AppFacade) {
        self.router = router
        self.appState = appState
        self.facade = facade
        
        initialize()
    }
    
    //MARK: - Getters
    
    var numberOfProjects: Int {
        return projects.value.count
    }
    
    func cellVMAtIndex(index: Int) -> ProjectCellViewModel {
        if let cached = cellViewModels[index] {
            return cached
        }
        
        let project = projects.value[index]
        let viewModel = ProjectCellViewModel(
            name: project.name,
            url: project.webUrl,
            selected: appState.selectedProjects.asObservable()
                .map() { ids in return ids.contains(project.id) }
        )
        return viewModel
    }
    
    func selected(index: Int) -> Bool {
        let project = projects.value[index]
        return appState.selectedProjects.value.contains(project.id)
    }
    
    var selectedUpdate: Observable<[ProjectId]> {
        return appState.selectedProjects.asObservable()
    }
    
    //MARK: - Actions
    
    private func initialize() {
        updateProjects()
    }
    
    private func updateProjects() {
        status.accept("Loading projects...")
        facade.projects(forceRefresh: true)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .success(let projects):
                    let sorted = projects
                        .sorted() { l, p in
                            return l.name < p.name
                    }
                    self.projects.accept(sorted)
                case .error(let error):
                    print("Failed to fetch projects: \(error)")
                }
                
                if self.projects.value.isEmpty {
                    self.status.accept("You don't have any projects available")
                } else {
                    self.status.accept(nil)
                }
            }
            .disposed(by: disposeBag)
    }
    
    func tapToIndex(index: Int) {
        let project = projects.value[index]
        var selectedProjects = appState.selectedProjects.value
        if let index = selectedProjects.firstIndex(of: project.id) {
            selectedProjects.remove(at: index)
        } else {
            selectedProjects.append(project.id)
        }
        appState.selectedProjects.accept(selectedProjects)
    }
    
    func confirm() {
        router.showRequestsController()
    }
}
