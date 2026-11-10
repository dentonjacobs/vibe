//
//  AppDelegate.swift
//  Vibe
//
//  Created by Thomas Schoffelen on 18/06/2016.
//  Copyright © 2016 thomasschoffelen. All rights reserved.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: TSCVibeWindow!

    private var refreshTimer: Timer?
    private var isLoading = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.styleMask.insert(.fullSizeContentView)
        window.backgroundColor = .white

        window.makeKeyAndOrderFront(nil)

        updateStats()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func updateStats() {
        // The OmniFocus query can take several seconds; don't start another while one is running.
        guard !isLoading else { return }
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let stats = TSCStatsLoader.getStats()
            DispatchQueue.main.async {
                self.isLoading = false
                self.window.displayStats(stats)
            }
        }
    }

}
