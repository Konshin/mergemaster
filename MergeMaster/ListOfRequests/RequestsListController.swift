//
//  RequestsListController.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import SnapKit
import RxSwift

private struct Constants {
    static let nameColumnIdentifier = "NAME"
}

final class RequestsListController: NSViewController {
    fileprivate let viewModel: RequestsListVM
    
    private let scrollView = NSScrollView()
    private lazy var tableView: NSTableView = {
        let view = NSTableView()
        view.headerView = nil
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    private let selectProjectsButton = NSButton()
    private let logoutButton = NSButton()
    private let exitButton = NSButton()
    private let titleLabel: NSTextField = {
        let text = NSTextField(string: "Merge requests")
        text.isBordered = false
        text.isSelectable = false
        text.backgroundColor = .clear
        return text
    }()
    
    fileprivate let disposeBag = DisposeBag()
    
    init(viewModel: RequestsListVM) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        viewModel.stopUpdates()
    }
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 250))
        self.view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeInterface()
        initializeRx()
    }
    
    //MARK: - Getters
    
    override var preferredContentSize: NSSize {
        get {
            return NSSize(width: 400, height: 250)
        }
        set {
            
        }
    }
    
    //MARK: - Actions
    
    private func initializeInterface() {
        view.addSubview(scrollView)
        scrollView.hasHorizontalScroller = false
        scrollView.snp.remakeConstraints() { make in
            make.left.bottom.right.equalToSuperview()
        }
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: Constants.nameColumnIdentifier))
        nameColumn.headerCell.stringValue = "Merge Requests"
        tableView.addTableColumn(nameColumn)
        
        scrollView.documentView = tableView
        
        let buttonsView = NSView()
        view.addSubview(buttonsView)
        buttonsView.snp.remakeConstraints() { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(30)
            make.bottom.equalTo(scrollView.snp.top)
        }
        
        selectProjectsButton.isBordered = false
        
        buttonsView.addSubview(selectProjectsButton)
        selectProjectsButton.snp.remakeConstraints() { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        
        exitButton.isBordered = false
        exitButton.title = "Exit"
        
        buttonsView.addSubview(exitButton)
        exitButton.snp.remakeConstraints() { make in
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        
        buttonsView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints {
            $0.center.equalToSuperview()
        }
        
        logoutButton.isBordered = false
        logoutButton.title = "Logout"
        
        buttonsView.addSubview(logoutButton)
        logoutButton.snp.remakeConstraints() { make in
            make.right.equalTo(exitButton.snp.left).offset(-8)
            make.centerY.equalToSuperview()
        }
    }
    
    private func initializeRx() {
        viewModel.selectProjectsTitle.drive(onNext: { [unowned self] title in
            self.selectProjectsButton.title = title
        })
            .disposed(by: disposeBag)
        
        selectProjectsButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.viewModel.reselectProjects()
        })
            .disposed(by: disposeBag)
        
        logoutButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.viewModel.logout()
        })
            .disposed(by: disposeBag)
        
        exitButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.viewModel.exit()
        })
            .disposed(by: disposeBag)
        
        viewModel.updateSignal
            .subscribe(onNext: { [weak self] in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }
}


extension RequestsListController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil
    }
    
}


extension RequestsListController: NSTableViewDelegate {
    
    private func createLabel() -> NSTextField {
        let view = NSTextField()
        view.isEditable = false
        view.isSelectable = false
        view.backgroundColor = .clear
        view.isBordered = false
        return view
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch viewModel.items[row] {
        case .cell(let viewModel):
            let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
            let view = createLabel()
            view.stringValue = viewModel.name
            
            let author = createLabel()
            author.stringValue = "Author: \(viewModel.userName)"
            
            let approvers = createLabel()
            switch viewModel.approvedBy.count {
            case 1:
                approvers.stringValue = "Approved: \(viewModel.approvedBy[0])"
            default:
                approvers.stringValue = "Approved: \(viewModel.approvedBy.count)"
            }
            
            let line = NSView()
            line.wantsLayer = true
            line.layer?.backgroundColor = NSColor.lightGray.cgColor
            
            [view, author, approvers, line]
                .forEach(container.addSubview(_:))
            
            view.snp.remakeConstraints {
                $0.top.equalToSuperview().inset(2)
                $0.leading.trailing.equalToSuperview()
            }
            author.snp.remakeConstraints {
                $0.leading.equalToSuperview()
                $0.bottom.equalToSuperview().inset(2)
            }
            approvers.snp.remakeConstraints {
                $0.trailing.equalToSuperview()
                $0.bottom.equalTo(author)
            }
            line.snp.remakeConstraints {
                $0.bottom.leading.trailing.equalToSuperview()
                $0.height.equalTo(1)
            }
            
            return container
        case .header(let header):
            let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
            container.wantsLayer = true
            
            let view = createLabel()
            view.font = NSFont.systemFont(ofSize: 12, weight: .bold)
            view.alignment = .left
            view.textColor = NSColor.linkColor
            view.backgroundColor = NSColor.headerColor.withAlphaComponent(0.1)
            view.stringValue = header.title
            
            [view]
                .forEach(container.addSubview)
            view.snp.remakeConstraints {
                $0.leading.equalToSuperview()
                $0.bottom.equalToSuperview().inset(2)
                $0.trailing.equalToSuperview()
            }
            
            return container
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        viewModel.handleTap(index: row)
        return false
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch viewModel.items[row] {
        case .cell:
            return 55
        case .header:
            return 24
        }
    }
    
}
