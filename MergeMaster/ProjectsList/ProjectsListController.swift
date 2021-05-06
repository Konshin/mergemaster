//
//  ProjectsListController.swift
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
    static let selectedColumnIdentifier = "SELECTED"
}

class ProjectsListController: NSViewController {
    fileprivate let viewModel: ProjectsListVM
    
    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = false
        scrollView.documentView = tableView
        return scrollView
    }()
    private lazy var tableView: NSTableView = {
        let tableView = NSTableView()
        tableView.rowHeight = 20
        tableView.dataSource = self
        tableView.delegate = self
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: Constants.nameColumnIdentifier))
        nameColumn.headerCell.stringValue = "Projects"
        nameColumn.width = 300
        tableView.addTableColumn(nameColumn)
        
        let selectedColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: Constants.selectedColumnIdentifier))
        selectedColumn.headerCell.stringValue = "Watch?"
        selectedColumn.headerCell.alignment = .center
        selectedColumn.width = 80
        tableView.addTableColumn(selectedColumn)
        return tableView
    }()
    private lazy var confirmButton: NSButton = {
        let confirmButton = NSButton()
        confirmButton.isBordered = false
        confirmButton.title = "Confirm"
        confirmButton.rx.tap.subscribe(onNext: { [unowned self] in
            self.viewModel.confirm()
        })
            .disposed(by: disposeBag)
        return confirmButton
    }()
    /// Status label
    private lazy var statusLabel: NSTextField = {
        let view = NSTextField()
        view.isSelectable = false
        view.isBordered = false
        view.alignment = .center
        view.backgroundColor = .clear
        view.isBezeled = false
        view.isEditable = false
        return view
    }()
    
    fileprivate let disposeBag = DisposeBag()
    
    init(viewModel: ProjectsListVM) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        get { return NSSize(width: 400, height: 250) }
        set {}
    }
    
    //MARK: - Actions
    
    private func initializeInterface() {
        [scrollView, confirmButton, statusLabel]
            .forEach(view.addSubview(_:))
        scrollView.snp.remakeConstraints() { make in
            make.left.top.right.equalToSuperview()
        }
        statusLabel.snp.remakeConstraints {
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.centerY.equalToSuperview()
        }
        confirmButton.snp.remakeConstraints() { make in
            make.top.equalTo(scrollView.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(20)
            make.centerX.equalToSuperview()
        }
    }
    
    private func initializeRx() {
        viewModel.projects.asDriver()
            .drive(onNext: { [unowned self] _ in
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.selectedUpdate.asDriver(onErrorJustReturn: [])
            .drive(onNext: { [unowned self] _ in
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        viewModel.status.asDriver()
            .drive(onNext: { [unowned self] text in
                self.statusLabel.stringValue = text ?? ""
            })
            .disposed(by: disposeBag)
    }
}


extension ProjectsListController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return viewModel.numberOfProjects
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return nil
    }
}


extension ProjectsListController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellViewModel = viewModel.cellVMAtIndex(index: row)
        
        let view: NSView
        switch tableColumn?.identifier.rawValue {
        case Constants.nameColumnIdentifier?:
            let textView = NSTextField(string: cellViewModel.name)
            textView.isBordered = false
            view = textView
        case Constants.selectedColumnIdentifier?:
            let check = NSButton()
            check.setButtonType(.switch)
            check.title = ""
            check.imagePosition = .imageOverlaps
            check.isEnabled = false
            check.state = viewModel.selected(index: row) ? .on : .off
            view = check
        default:
            return nil
        }
        
        return view
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        viewModel.tapToIndex(index: row)
        
        return false
    }
}
