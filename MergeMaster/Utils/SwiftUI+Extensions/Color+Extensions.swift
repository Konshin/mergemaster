//
//  Color+Extensions.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 08.10.2024.
//  Copyright © 2024 Konshin. All rights reserved.
//

import SwiftUI

extension Color {
  static let appWarning = Color("Warning")
  static let appError = Color("Error")
  static let appSuccess = Color("Success")
}

extension NSColor {
  static let secondary: NSColor = NSColor(name: nil) { appearance in
    switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
    case .darkAqua:
      return NSColor.lightGray
    default:
      return NSColor.darkGray
    }
  }
}
