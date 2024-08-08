//
//  SkeletonView.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.08.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI

struct SkeletonView: View {
  var body: some View {
    GeometryReader { geometry in
      Color(.separatorColor)
        .cornerRadius(min(geometry.size.height * 0.25, 4))
    }
  }
}

#Preview {
  VStack {
    SkeletonView()
      .frame(height: 10)
    SkeletonView()
      .frame(height: 20)
    Spacer()
  }
  .padding()
}
