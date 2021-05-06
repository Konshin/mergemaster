//
//  AuthorizationController.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class AuthorizationController: NSViewController {
    let viewModel: AuthorizationVM
    @IBOutlet private var titleLabel: NSTextField!
    @IBOutlet private var errorLabel: NSTextField!
    @IBOutlet private var tokenField: NSTextField!
    @IBOutlet private var gitlabURLField: NSTextField!
    @IBOutlet private var loginButton: NSButton!
    @IBOutlet private var exitButton: NSButton!
    
    private let disposeBag = DisposeBag()
    
    init(viewModel: AuthorizationVM) {
        self.viewModel = viewModel
        
        super.init(nibName: "AuthorizationController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialize()
    }
    
    //MARK: - Getters
    
    override var preferredContentSize: NSSize {
        set {
            
        }
        get {
            return self.view.bounds.size
        }
    }
    
    //MARK: - Actions
    
    private func initialize() {
        viewModel.setup()
        
        titleLabel.stringValue = viewModel.authTitle
        errorLabel.stringValue = ""
        gitlabURLField.stringValue = viewModel.url.value ?? ""
        tokenField.stringValue = viewModel.token.value ?? ""
        
        tokenField.rx.text
            .bind(to: viewModel.token)
            .disposed(by: disposeBag)
        gitlabURLField.rx.text
            .bind(to: viewModel.url)
            .disposed(by: disposeBag)
        viewModel.loginEnabled
            .bind(to: loginButton.rx.isEnabled)
            .disposed(by: disposeBag)
        loginButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.loginWithCredentials()
            })
            .disposed(by: disposeBag)
        exitButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.exit()
            })
            .disposed(by: disposeBag)
    }
    
    private func loginWithCredentials() {
        errorLabel.stringValue = ""
        viewModel.authorize()
    }
    
    private func exit() {
        viewModel.exit()
    }
}
