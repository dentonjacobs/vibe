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
    private var hasLoadedOnce = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        addRefreshMenuItem()
        window.makeKeyAndOrderFront(nil)

        updateStats(showProgress: true)

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateStats(showProgress: false)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    /// File › Refresh (⌘R).
    private func addRefreshMenuItem() {
        guard let fileMenu = NSApp.mainMenu?.item(withTitle: "File")?.submenu else { return }
        let item = NSMenuItem(title: "Refresh", action: #selector(refresh(_:)), keyEquivalent: "r")
        item.target = self
        fileMenu.insertItem(item, at: 0)
        fileMenu.insertItem(.separator(), at: 1)
    }

    @objc func refresh(_ sender: Any?) {
        updateStats(showProgress: true)
    }

    /// - Parameter showProgress: show "Updating…" while loading. Off for the background timer
    ///   so the label doesn't flicker every 30 seconds.
    func updateStats(showProgress: Bool) {
        // The OmniFocus query can take several seconds; don't start another while one is running.
        guard !isLoading else { return }
        isLoading = true
        if showProgress || !hasLoadedOnce {
            window.showUpdating()
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let stats = TSCStatsLoader.getStats()
            DispatchQueue.main.async {
                self.isLoading = false
                self.hasLoadedOnce = true
                self.window.displayStats(stats, updatedAt: Date())
            }
        }
    }

}
