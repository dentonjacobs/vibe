//
//  TSCVibeWindow.swift
//  Vibe
//
//  Created by Thomas Schoffelen on 18/06/2016.
//  Copyright © 2016 thomasschoffelen. All rights reserved.
//

import Cocoa

class TSCVibeWindow: NSWindow {

    @IBOutlet var weekGraph: NSView!
    @IBOutlet var monthGraph: NSView!
    @IBOutlet var weekdayGraph: NSView!

    @IBOutlet var weekHeader: NSTextField!
    @IBOutlet var monthHeader: NSTextField!
    @IBOutlet var weekdayHeader: NSTextField!

    @IBOutlet var titleLabel: NSTextField?
    @IBOutlet var subtitleLabel: NSTextField?

    private let headingLabel = NSTextField(labelWithString: "")
    private let updatedLabel = NSTextField(labelWithString: "")

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .vibeBackground
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        styleMask.insert(.fullSizeContentView)

        addHeading()
        addCard(around: weekGraph, header: weekHeader)
        addCard(around: monthGraph, header: monthHeader)
        addCard(around: weekdayGraph, header: weekdayHeader)
    }

    private func addHeading() {
        guard let contentView, let titleLabel else { return }

        headingLabel.attributedStringValue = NSAttributedString(
            string: "VIBE · OMNIFOCUS",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor,
                .kern: 1.2,
            ])

        updatedLabel.font = .systemFont(ofSize: 11)
        updatedLabel.textColor = .tertiaryLabelColor
        updatedLabel.alignment = .right

        for label in [headingLabel, updatedLabel] {
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
        }

        NSLayoutConstraint.activate([
            headingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            headingLabel.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -2),
            updatedLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            updatedLabel.firstBaselineAnchor.constraint(equalTo: headingLabel.firstBaselineAnchor),
        ])
    }

    /// Puts a rounded card behind a chart and its section header.
    private func addCard(around chart: NSView, header: NSTextField) {
        guard let contentView else { return }

        header.font = .systemFont(ofSize: 13, weight: .semibold)
        header.textColor = .labelColor

        let card = TSCFillView(frame: .zero)
        card.fillColor = .vibeCard
        card.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card, positioned: .below, relativeTo: nil)

        let padding: CGFloat = 14
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: chart.leadingAnchor, constant: -padding),
            card.trailingAnchor.constraint(equalTo: chart.trailingAnchor, constant: padding),
            card.topAnchor.constraint(equalTo: header.topAnchor, constant: -padding),
            card.bottomAnchor.constraint(equalTo: chart.bottomAnchor, constant: padding),
        ])
    }

    func showUpdating() {
        updatedLabel.stringValue = "Updating…"
    }

    func displayStats(_ stats: TSCStats?, updatedAt date: Date) {
        guard let stats else {
            titleLabel?.stringValue = "Couldn't read OmniFocus."
            subtitleLabel?.stringValue = "Make sure OmniFocus is running and Vibe is allowed to control it (System Settings › Privacy & Security › Automation)."
            updatedLabel.stringValue = "Update failed"
            return
        }

        render(stats.lastSevenDays, in: weekGraph, color: .vibePurple)
        render(stats.months, in: monthGraph, color: .vibeBlue)
        render(stats.weekdays, in: weekdayGraph, color: .vibeSlate)

        titleLabel?.stringValue = "\(stats.complete.formatted()) \(stats.complete == 1 ? "task" : "tasks") completed"
        subtitleLabel?.stringValue = [
            "\(stats.open.formatted()) open",
            "\(stats.completedToday.formatted()) today",
            "\(stats.completedThisWeek.formatted()) this week",
        ].joined(separator: " · ")
        updatedLabel.stringValue = "Updated \(date.formatted(date: .omitted, time: .shortened))"
    }

    private func render(_ bars: [TSCBar], in container: NSView, color: NSColor) {
        // Replace the previous chart rather than stacking a new one on top of it.
        container.subviews.filter { $0 is TSCBarChartView }.forEach { $0.removeFromSuperview() }

        let chartView = TSCBarChartView(frame: container.bounds, bars: bars, barColor: color)
        chartView.autoresizingMask = [.height, .width]
        chartView.translatesAutoresizingMaskIntoConstraints = true
        container.addSubview(chartView)
    }

}
