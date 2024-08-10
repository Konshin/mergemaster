//
//  ErrorView.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 10.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
  let error: String
  let reload: () -> Void

  init(_ error: String, reload: @escaping () -> Void) {
    self.error = error
    self.reload = reload
  }

  var body: some View {
    VStack {
      Text(error)
      Button("Reload", action: reload)
      .foregroundColor(.accentColor)
      .buttonStyle(.plain)
    }
    .frame(maxHeight: .infinity, alignment: .center)
  }
}

#Preview {
  ErrorView("some error") {
    print("reload")
  }
}
