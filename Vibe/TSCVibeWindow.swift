//
//  TSCVibeWindow.swift
//  Vibe
//
//  Created by Thomas Schoffelen on 18/06/2016.
//  Copyright © 2016 thomasschoffelen. All rights reserved.
//

import Cocoa

typealias StatsDictionary = [String: [String: Int]]

class TSCVibeWindow: NSWindow {

    @IBOutlet var weekGraph: NSView!
    @IBOutlet var monthGraph: NSView!
    @IBOutlet var weekdayGraph: NSView!

    @IBOutlet var titleLabel: NSTextField?
    @IBOutlet var subtitleLabel: NSTextField?

    func displayStats(_ stats: StatsDictionary) {
        // Loader returns an empty dictionary when OmniFocus can't be queried.
        guard let totals = stats["totals"] else {
            titleLabel?.stringValue = "Couldn't read OmniFocus."
            subtitleLabel?.stringValue = "Make sure OmniFocus is running and Vibe is allowed to control it (System Settings › Privacy & Security › Automation)."
            return
        }

        render(stats["days"] ?? [:], in: weekGraph,
               color: NSColor(red: 0.60, green: 0.55, blue: 0.85, alpha: 1.00))
        render(stats["months"] ?? [:], in: monthGraph,
               color: NSColor(red: 0.36, green: 0.65, blue: 0.90, alpha: 1.00))
        render(stats["weekdays"] ?? [:], in: weekdayGraph,
               color: NSColor(red: 0.21, green: 0.26, blue: 0.33, alpha: 1.00))

        titleLabel?.stringValue = "\(totals["complete"] ?? 0) tasks completed."
        subtitleLabel?.stringValue = "\(totals["incomplete"] ?? 0) tasks are currently open."
    }

    private func render(_ data: [String: Int], in container: NSView, color: NSColor) {
        // Replace the previous chart rather than stacking a new one on top of it.
        container.subviews.filter { $0 is TSCBarChartView }.forEach { $0.removeFromSuperview() }

        let chartView = TSCBarChartView(frame: container.bounds, barData: data, barColor: color)
        chartView.autoresizingMask = [.height, .width]
        chartView.translatesAutoresizingMaskIntoConstraints = true
        container.addSubview(chartView)
    }

}
