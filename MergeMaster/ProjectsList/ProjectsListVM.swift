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
    let searchText = PublishSubject<String>()
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
            nameSpace: project.namespace?.name,
            url: project.webUrl,
            selected: appState.selectedProjects.asObservable()
                .map() { ids in return ids.contains(project) }
        )
        return viewModel
    }
    
    func selected(index: Int) -> Bool {
        let project = projects.value[index]
        return appState.selectedProjects.value.contains(project)
    }
    
    var selectedUpdate: Observable<[ProjectId]> {
        return appState.selectedProjects.map { projects in projects.map { $0.id } }
    }
    
    //MARK: - Actions
    
    private func initialize() {
        searchText
            .skip(1)
            .do(onNext: { [weak self] _ in
                self?.status.accept("Search for projects...")
                self?.projects.accept([])
            })
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                self?.updateProjects(searchText: text, force: false)
            })
            .disposed(by: disposeBag)
        
        updateProjects(force: true)
    }
    
    private func updateProjects(searchText: String = "", force: Bool) {
        if searchText.isEmpty {
            status.accept("Loading projects...")
        }
        facade.projects(search: searchText, forceRefresh: force)
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
                    if searchText.isEmpty {
                        self.status.accept("You don't have any projects available")
                    } else {
                        self.status.accept("No projects found")
                    }
                } else {
                    self.status.accept(nil)
                }
            }
            .disposed(by: disposeBag)
    }
    
    func tapToIndex(index: Int) {
        let project = projects.value[index]
        var selectedProjects = appState.selectedProjects.value
        if let index = selectedProjects.firstIndex(of: project) {
            selectedProjects.remove(at: index)
        } else {
            selectedProjects.append(project)
        }
        appState.selectedProjects.accept(selectedProjects)
    }
    
    func confirm() {
        router.showRequestsController()
    }
}
