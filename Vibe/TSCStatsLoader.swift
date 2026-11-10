//
//  TSCStatsLoader.swift
//  Vibe
//
//  Created by Thomas Schoffelen on 18/06/2016.
//  Copyright © 2016 thomasschoffelen. All rights reserved.
//

import Foundation

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
    /// Returns an empty dictionary if OmniFocus could not be queried.
    static func getStats() -> StatsDictionary {
        guard let output = runScript() else { return [:] }
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

    static func makeStats(from output: String, calendar: Calendar = .current, now: Date = Date()) -> StatsDictionary {
        var countsDays: [String: Int] = [:]
        var countsMonths: [String: Int] = [:]
        var countsDayOfWeek: [String: Int] = [:]
        var countIncomplete = 0
        var countComplete = 0

        let monthFormatter = DateFormatter()
        monthFormatter.calendar = calendar
        monthFormatter.dateFormat = "MMM"

        let currentYear = calendar.component(.year, from: now)
        let sevenDaysAgo = now.addingTimeInterval(-7 * 86400)

        for line in output.split(whereSeparator: \.isNewline) {
            if line == "missing value" {
                countIncomplete += 1
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

            countComplete += 1
            let then = calendar.dateComponents([.weekday, .day, .month, .year], from: date)
            guard let year = then.year, let month = then.month,
                  let day = then.day, let weekday = then.weekday else { continue }

            // Keys are "sortKey|Label"; the chart sorts by key and shows the label.
            if year == currentYear {
                let key = String(format: "%02d|%@", month, monthFormatter.string(from: date))
                countsMonths[key, default: 0] += 1
            }

            if date >= sevenDaysAgo {
                let key = String(format: "%04d%02d%02d|%d-%d", year, month, day, day, month)
                countsDays[key, default: 0] += 1
            }

            // Calendar weekday is 1 = Sunday; order the chart Monday first.
            let mondayFirst = (weekday + 5) % 7
            let key = "\(mondayFirst)|\(calendar.shortWeekdaySymbols[weekday - 1])"
            countsDayOfWeek[key, default: 0] += 1
        }

        return [
            "days": countsDays,
            "months": countsMonths,
            "weekdays": countsDayOfWeek,
            "totals": [
                "complete": countComplete,
                "incomplete": countIncomplete,
            ],
        ]
    }

}
