//
//  TSCBarChartView.swift
//  Vibe
//
//  Created by Thomas Schoffelen on 18/06/2016.
//  Copyright © 2016 thomasschoffelen. All rights reserved.
//

import Cocoa

extension NSColor {
    static func adaptive(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }
    }

    static let vibeBackground = adaptive(light: .white, dark: NSColor(white: 0.11, alpha: 1))
    static let vibeCard = adaptive(light: NSColor(white: 0.965, alpha: 1), dark: NSColor(white: 1, alpha: 0.06))

    static let vibePurple = adaptive(light: NSColor(red: 0.60, green: 0.55, blue: 0.85, alpha: 1),
                                     dark: NSColor(red: 0.70, green: 0.65, blue: 0.95, alpha: 1))
    static let vibeBlue = adaptive(light: NSColor(red: 0.36, green: 0.65, blue: 0.90, alpha: 1),
                                   dark: NSColor(red: 0.45, green: 0.72, blue: 0.98, alpha: 1))
    static let vibeSlate = adaptive(light: NSColor(red: 0.21, green: 0.26, blue: 0.33, alpha: 1),
                                    dark: NSColor(red: 0.66, green: 0.72, blue: 0.80, alpha: 1))
}

/// Layer-backed solid fill that re-resolves its (adaptive) color when light/dark mode changes.
final class TSCFillView: NSView {

    var fillColor: NSColor = .clear { didSet { needsDisplay = true } }
    var isMuted = false { didSet { needsDisplay = true } }
    var cornerRadius: CGFloat = 0 { didSet { needsDisplay = true } }
    var roundsTopCornersOnly = false { didSet { needsDisplay = true } }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        guard let layer else { return }
        // Called with this view's appearance current, so adaptive colors resolve correctly.
        layer.backgroundColor = (isMuted ? fillColor.withAlphaComponent(0.4) : fillColor).cgColor
        layer.cornerRadius = cornerRadius
        layer.maskedCorners = roundsTopCornersOnly
            ? [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}

/// Simple bar chart: one bar per entry, values above the bars, labels underneath.
/// Highlighted bars (e.g. today) are drawn in full color, the rest muted.
class TSCBarChartView: NSView {

    private let bars: [TSCBar]
    private let barColor: NSColor

    private let axisHeight: CGFloat = 20
    private let valueHeight: CGFloat = 15
    private let maxBarWidth: CGFloat = 40

    init(frame: CGRect, bars: [TSCBar], barColor: NSColor) {
        self.bars = bars
        self.barColor = barColor
        super.init(frame: frame)
        renderBars()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func renderBars() {
        guard !bars.isEmpty else { return }

        let maxValue = max(1, bars.map(\.value).max() ?? 1)
        let plotHeight = frame.height - axisHeight - valueHeight
        let slotWidth = frame.width / CGFloat(bars.count)
        let barWidth = min(maxBarWidth, slotWidth - 6)

        for (index, bar) in bars.enumerated() {
            let slotX = CGFloat(index) * slotWidth
            let barX = slotX + (slotWidth - barWidth) / 2
            let barHeight = max(2, plotHeight * CGFloat(bar.value) / CGFloat(maxValue))

            let barView = TSCFillView(frame: CGRect(x: barX, y: axisHeight, width: barWidth, height: barHeight))
            barView.fillColor = barColor
            barView.isMuted = !bar.isHighlighted
            barView.cornerRadius = min(5, barWidth / 4)
            barView.roundsTopCornersOnly = true
            addSubview(barView)

            let weight: NSFont.Weight = bar.isHighlighted ? .semibold : .regular
            let textColor: NSColor = bar.isHighlighted ? .labelColor : .secondaryLabelColor

            addSubview(makeLabel(
                bar.value.formatted(),
                frame: CGRect(x: slotX, y: axisHeight + barHeight + 1, width: slotWidth, height: valueHeight - 2),
                font: .monospacedDigitSystemFont(ofSize: 10, weight: weight),
                color: textColor))

            addSubview(makeLabel(
                bar.label,
                frame: CGRect(x: slotX - 3, y: 0, width: slotWidth + 6, height: axisHeight - 4),
                font: .systemFont(ofSize: 11, weight: bar.isHighlighted ? .semibold : .medium),
                color: textColor))
        }
    }

    private func makeLabel(_ text: String, frame: CGRect, font: NSFont, color: NSColor) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.frame = frame
        field.textColor = color
        field.alignment = .center
        field.font = font
        field.lineBreakMode = .byClipping
        return field
    }

}
