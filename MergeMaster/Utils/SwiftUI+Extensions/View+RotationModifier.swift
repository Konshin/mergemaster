//
//  RotationModifier.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 14.01.2025.
//  Copyright © 2025 Konshin. All rights reserved.
//

import SwiftUI

struct RotationModifier: ViewModifier {
  @State private var angle: CGFloat = 0
  var isAnimating: Bool = false

  private let timer = Timer.publish(every: 1 / 30, on: .main, in: .common)
    .autoconnect()

  func body(content: Content) -> some View {
    content
      .rotationEffect(.degrees(angle))
      .onReceive(timer.filter { _ in self.isAnimating }) { _ in
        self.angle = (self.angle + 6).remainder(dividingBy: 360)
      }
  }
}
