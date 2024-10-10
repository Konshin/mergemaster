//
//  RequestListRow.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.10.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI

struct RequestListRow: View {
  let item: Item
  @State private var overText = false

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(item.title)
        .lineLimit(3)
      HStack(alignment: .bottom) {
        Text(item.author).foregroundColor(.secondary)
          .lineLimit(1)
          .layoutPriority(100)
        Spacer()
        HStack(spacing: 2) {
          Text(item.status)
            .foregroundColor(color(highlighting: item.statusHighlighting))
            .lineLimit(1)
          if let description = item.statusDescription {
            Button {
              overText = true
            } label: {
              Image(systemName: "info.circle")
            }
            .buttonStyle(.borderless)
            .help(LocalizedStringKey(description))
            .popover(isPresented: $overText) {
              Text(LocalizedStringKey(description))
                .padding(4)
                .multilineTextAlignment(.leading)
                .frame(width: 200)
            }
          }
        }
        .layoutPriority(150)
      }
    }
    .padding(.vertical, 2)
    .background(Color(.textBackgroundColor).opacity(0.01))
  }

  private func color(highlighting: StatusHighlighting) -> Color {
    switch highlighting {
    case .none:
      return Color(.labelColor)
    case .red:
      return Color.appError
    case .yellow:
      return Color.appWarning
    case .green:
      return Color.appSuccess
    }
  }
}

extension RequestListRow {
  struct Item: Identifiable, Equatable {
    var id: Int
    var title: String
    var author: String
    var status: String
    var statusDescription: String?
    var statusHighlighting: StatusHighlighting = .none
  }

  enum StatusHighlighting {
    case none, red, yellow, green
  }
}

@available(macOS 14.0, *)
#Preview(traits: .fixedLayout(width: 300, height: 200)) {
  let item = RequestListRow.Item(
    id: 0,
    title: "Merge request title",
    author: "Konshin Aleksei Mikhailovich",
    status: MergeRequest.DetailedStatus.jiraAssociationMissing.title,
    statusDescription: MergeRequest.DetailedStatus.jiraAssociationMissing.description,
    statusHighlighting: .green
  )
  RequestListRow(item: item)
}
