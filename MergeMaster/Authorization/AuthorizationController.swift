//
//  AuthorizationController.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Cocoa
import Combine

final class AuthorizationController: NSViewController {
  let viewModel: AuthorizationVM
  @IBOutlet private var titleLabel: NSTextField!
  @IBOutlet private var errorLabel: NSTextField!
  @IBOutlet private var tokenField: NSTextField!
  @IBOutlet private var gitlabURLField: NSTextField!
  @IBOutlet private var loginButton: NSButton!
  @IBOutlet private var exitButton: NSButton!

  private var bindings = Set<AnyCancellable>()

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

    tokenField.delegate = self
    gitlabURLField.delegate = self

    viewModel.loginEnabled
      .sink(receiveValue: { [loginButton] isEnabled in
        loginButton?.isEnabled = isEnabled
      })
      .store(in: &bindings)
    loginButton.target = self
    loginButton.action = #selector(loginWithCredentials)

    exitButton.target = self
    exitButton.action = #selector(self.exit)
  }

  @objc private func loginWithCredentials() {
    errorLabel.stringValue = ""
    viewModel.authorize()
  }

  @objc private func exit() {
    viewModel.exit()
  }
}

// MARK: - NSTextFieldDelegate
extension AuthorizationController: NSTextFieldDelegate {
  func controlTextDidChange(_ obj: Notification) {
    switch obj.object as? NSTextField {
    case tokenField:
      viewModel.token.send(tokenField.stringValue)
    case gitlabURLField:
      viewModel.url.send(tokenField.stringValue)
    default:
      break
    }
  }
}
