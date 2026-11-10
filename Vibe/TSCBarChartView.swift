//
//  TSCBarChartView.swift
//  Vibe
//
//  Created by Thomas Schoffelen on 18/06/2016.
//  Copyright © 2016 thomasschoffelen. All rights reserved.
//

import Cocoa

extension NSView {
    var backgroundColor: NSColor? {
        get {
            guard let cgColor = layer?.backgroundColor else { return nil }
            return NSColor(cgColor: cgColor)
        }

        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }
}

/// Simple bar chart. Keys of `barData` are "sortKey|Label"; bars are ordered by
/// the full key and labelled with the part after the last "|".
class TSCBarChartView: NSView {

    private let barData: [String: Int]
    private let barColor: NSColor

    init(frame: CGRect, barData: [String: Int], barColor: NSColor) {
        self.barData = barData
        self.barColor = barColor
        super.init(frame: frame)
        renderBarData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func renderBarData() {
        let bars = barData
            .filter { $0.value > 0 }
            .sorted { $0.key < $1.key }
        guard !bars.isEmpty else { return }

        let maxValue = max(1, bars.map(\.value).max() ?? 1)
        let spacing: CGFloat = 4
        let barTop: CGFloat = 20
        let barHeight = frame.height - barTop
        let barWidth = frame.width / CGFloat(bars.count) - spacing

        for (index, bar) in bars.enumerated() {
            let label = bar.key.split(separator: "|").last.map(String.init) ?? bar.key
            let x = CGFloat(index) * (barWidth + spacing)
            let calculatedHeight = barHeight * (CGFloat(bar.value) / CGFloat(maxValue))
            let fitsInside = calculatedHeight >= 18

            let barView = NSView(frame: CGRect(x: x, y: barTop, width: barWidth, height: calculatedHeight))
            barView.backgroundColor = barColor

            // Value sits inside the top of the bar, or just above it when the bar is too short.
            let valueLabel = makeLabel(
                String(bar.value),
                frame: CGRect(x: x, y: barTop, width: barWidth,
                              height: fitsInside ? calculatedHeight - 2 : calculatedHeight + 18),
                font: .systemFont(ofSize: 10),
                color: fitsInside ? NSColor(white: 1, alpha: 0.7) : barColor)

            let labelLabel = makeLabel(
                label,
                frame: CGRect(x: x - 3, y: 0, width: barWidth + 6, height: barTop - 3),
                font: .systemFont(ofSize: 11, weight: .semibold),
                color: barColor)

            addSubview(barView)
            addSubview(valueLabel)
            addSubview(labelLabel)
        }
    }

    private func makeLabel(_ text: String, frame: CGRect, font: NSFont, color: NSColor) -> NSTextField {
        let field = NSTextField(frame: frame)
        field.stringValue = text
        field.isBordered = false
        field.isEditable = false
        field.isSelectable = false
        field.drawsBackground = false
        field.textColor = color
        field.alignment = .center
        field.usesSingleLineMode = true
        field.font = font
        return field
    }

}
