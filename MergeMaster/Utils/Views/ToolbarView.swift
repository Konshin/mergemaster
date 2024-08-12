//
//  Toolbar.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 09.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI

struct ToolbarView<LeadingViews: View, TrailingViews: View>: View {
  let title: String?
  @ViewBuilder
  var leadingViews: () -> LeadingViews
  @ViewBuilder
  var trailingViews: () -> TrailingViews

  var body: some View {
    HStack(spacing: 16) {
      leadingViews()
      Spacer()
      if let title {
        Text(title)
          .font(.headline)
        Spacer()
      }
      trailingViews()
    }
    .frame(height: 30)
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 8)
    .foregroundColor(Color(.textBackgroundColor))
    .background(Color.accentColor)
  }
}

#Preview {
  ToolbarView(
    title: "test") {
      Text("1")
      Text("2")
    } trailingViews: {
      Text("3")
      Text("4")
    }
}
