//
//  MenuIconView.swift
//  MergeMaster
//
//  Created by Aleksey Konshin on 15.01.2025.
//  Copyright © 2025 Konshin. All rights reserved.
//

import AppKit

final class MenuIconView: NSView {
  struct Item {
    var color: NSColor
    var value: Int
  }

  private var items: [Item] = []
  private let image = NSImage(named: "mr_status_icon_16") ?? NSImage()

  init(items: [Item], rect: NSRect) {
    self.items = items
    super.init(frame: rect)
  }
               
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    // prepare
    NSColor.clear.drawSwatch(in: dirtyRect)
    guard let ctx = NSGraphicsContext.current else { return }

    // draw
    let areSegmentsDrown = drawSegments(ctx: ctx, items: self.items, rect: dirtyRect)
    if areSegmentsDrown {
      drawIcon(ctx: ctx, rect: dirtyRect)
    }
  }

  private func drawSegments(ctx: NSGraphicsContext, items: [Item], rect: NSRect) -> Bool {
    let cgCtx = ctx.cgContext
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    let total = CGFloat(items.reduce(0, { $0 + $1.value }))

    if total == 0 {
      cgCtx.setFillColor(NSColor.secondary.cgColor)

      cgCtx.move(to: center)
      cgCtx.addArc(
        center: center,
        radius: radius,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: false
      )
      cgCtx.fillPath()
    } else {
      var startAngle: CGFloat = .pi * 0.5
      let maxAngle = startAngle + .pi * 1.1
      for item in items {
        guard item.value > 0 else { continue }
        cgCtx.setFillColor(item.color.cgColor)

        let endAngle = startAngle - (CGFloat(item.value) / total) * (.pi * 2)
        cgCtx.move(to: center)
        cgCtx.addArc(
          center: center,
          radius: radius,
          startAngle: startAngle,
          endAngle: endAngle,
          clockwise: true
        )
        cgCtx.fillPath()

        startAngle = endAngle
      }
    }
    return true
  }

  private func drawIcon(ctx: NSGraphicsContext, rect: NSRect) {
    let availableSide = min(rect.width, rect.height) * 0.6
    let scale: CGFloat = availableSide / max(image.size.width, image.size.height)
    let imageSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let origin = CGPoint(
      x: rect.minX + (rect.width - imageSize.width) / 2,
      y: rect.minY + (rect.height - imageSize.height) / 2
    )
    image.draw(
      in: NSRect(
        origin: origin,
        size: imageSize
      ),
      from: .zero,
      operation: .destinationOut,
      fraction: 1
    )
  }
}

extension MenuIconView {
  func configure(_ items: [Item]) {
    self.items = items
    self.needsDisplay = true
  }
}

private let colors: [NSColor] = [
  .controlAccentColor,
  .blue,
  .yellow,
  .brown,
  .cyan
]
private func color(for index: Int) -> NSColor {
  let colorIndex = index % colors.count
  return colors[colorIndex]
}

@available(macOS 14.0, *)
#Preview {
  let items = (0..<1).map { idx in
    MenuIconView.Item(
      color: color(for: idx),
      value: idx == 1 ? 3 : 1
    )
  }
  MenuIconView(items: items, rect: NSRect(x: 0, y: 0, width: 20, height: 20))
}
