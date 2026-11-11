//
//  TSCStatsLoader.swift
//  Vibe
//
//  Created by Thomas Schoffelen on 18/06/2016.
//  Copyright © 2016 thomasschoffelen. All rights reserved.
//

import Foundation

struct TSCBar: Equatable {
    let label: String
    let value: Int
    let isHighlighted: Bool
}

struct TSCStats {
    var lastSevenDays: [TSCBar] = []
    var months: [TSCBar] = []
    var weekdays: [TSCBar] = []

    var complete = 0
    var open = 0
    var completedToday = 0
    var completedThisWeek = 0
}

enum TSCStatsLoader {

    /// Emits one line per leaf task: "missing value" for open tasks, otherwise
    /// "<year> <month> <day> <seconds since midnight>" of the completion date.
    /// Plain numbers avoid depending on the locale-specific date text AppleScript produces.
    private static let script = """
        on fmt(theDates)
            set out to ""
            repeat with d in theDates
                set d to contents of d
                if d is missing value then
                    set out to out & "missing value" & linefeed
                else
                    set out to out & (year of d) & " " & ((month of d) as integer) & " " & (day of d) & " " & (time of d) & linefeed
                end if
            end repeat
            return out
        end fmt

        tell application "OmniFocus"
            tell front document
                set theOutput to ""
                repeat with p in (every flattened project)
                    set theOutput to theOutput & my fmt(completion date of (every flattened task of p where its number of tasks = 0))
                end repeat
                set theOutput to theOutput & my fmt(completion date of (every inbox task where its number of tasks = 0))
            end tell
        end tell
        return theOutput
        """

    /// Queries OmniFocus and buckets completed tasks. Blocking; call off the main thread.
    /// Returns nil if OmniFocus could not be queried.
    static func getStats() -> TSCStats? {
        guard let output = runScript() else { return nil }
        return makeStats(from: output)
    }

    /// Runs the script via osascript. NSAppleScript must be used on the main thread,
    /// and this query takes several seconds on a large database.
    private static func runScript() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-"]

        let input = Pipe()
        let output = Pipe()
        let errors = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = errors

        do {
            try process.run()
        } catch {
            NSLog("Vibe: failed to launch osascript: \(error)")
            return nil
        }

        input.fileHandleForWriting.write(Data(script.utf8))
        try? input.fileHandleForWriting.close()

        let data = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = errors.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            NSLog("Vibe: OmniFocus query failed: \(String(decoding: errorData, as: UTF8.self))")
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// Counts per bar, keyed by a sort key so bars come out in chronological order.
    private struct Buckets {
        private var entries: [String: (label: String, count: Int)] = [:]

        mutating func add(key: String, label: String) {
            entries[key, default: (label, 0)].count += 1
        }

        func bars(highlighting highlightKey: String) -> [TSCBar] {
            entries
                .sorted { $0.key < $1.key }
                .map { TSCBar(label: $0.value.label, value: $0.value.count, isHighlighted: $0.key == highlightKey) }
        }
    }

    static func makeStats(from output: String, calendar: Calendar = .current, now: Date = Date()) -> TSCStats {
        var stats = TSCStats()
        var days = Buckets()
        var months = Buckets()
        var weekdays = Buckets()

        let monthFormatter = DateFormatter()
        monthFormatter.calendar = calendar
        monthFormatter.dateFormat = "MMM"

        // Day + month in the user's regional order and separators (e.g. "11/10" in the US, "10.11." in Germany).
        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.locale = .autoupdatingCurrent
        dayFormatter.setLocalizedDateFormatFromTemplate("Md")

        func dayKey(_ date: Date) -> String {
            let c = calendar.dateComponents([.year, .month, .day], from: date)
            return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
        }
        func monthKey(_ date: Date) -> String {
            String(format: "%02d", calendar.component(.month, from: date))
        }
        // Calendar weekday is 1 = Sunday; order the chart Monday first.
        func weekdayKey(_ date: Date) -> String {
            String((calendar.component(.weekday, from: date) + 5) % 7)
        }

        let currentYear = calendar.component(.year, from: now)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 86400)

        for line in output.split(whereSeparator: \.isNewline) {
            if line == "missing value" {
                stats.open += 1
                continue
            }

            let parts = line.split(separator: " ").compactMap { Int($0) }
            guard parts.count == 4 else { continue }

            var components = DateComponents()
            components.year = parts[0]
            components.month = parts[1]
            components.day = parts[2]
            components.second = parts[3]
            guard let date = calendar.date(from: components) else { continue }

            stats.complete += 1
            if calendar.isDate(date, inSameDayAs: now) {
                stats.completedToday += 1
            }
            if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
                stats.completedThisWeek += 1
            }

            if calendar.component(.year, from: date) == currentYear {
                months.add(key: monthKey(date), label: monthFormatter.string(from: date))
            }
            if date >= sevenDaysAgo {
                days.add(key: dayKey(date), label: dayFormatter.string(from: date))
            }
            let weekday = calendar.component(.weekday, from: date)
            weekdays.add(key: weekdayKey(date), label: calendar.shortWeekdaySymbols[weekday - 1])
        }

        stats.lastSevenDays = days.bars(highlighting: dayKey(now))
        stats.months = months.bars(highlighting: monthKey(now))
        stats.weekdays = weekdays.bars(highlighting: weekdayKey(now))
        return stats
    }

}
