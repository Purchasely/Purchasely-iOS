//
//  SampleLogger.swift
//  PurchaselySampleV2
//
//  A PLYLogging sink that buffers the SDK's log messages (capped, persisted to UserDefaults) and is
//  observable for the Logs screen.
//

import Foundation
import os.log
import Purchasely

final class SampleLogger: PLYLogging, ObservableObject {

    /// Mirrors every SDK message into the unified log.
    ///
    /// `PLYLogger` writes with `print()`, which reaches stdout and never the unified log — so a
    /// device not attached to Xcode shows nothing in Console.app or `idevicesyslog`. Measured:
    /// filtering a device's log to this app's process while the SDK was running returned zero
    /// lines from it. Re-emitting here is what makes a device log readable at all.
    ///
    /// `%{public}@` is load-bearing — os_log redacts dynamic strings to `<private>` by default,
    /// which would reduce every line to noise. Acceptable because this is the sample; do not copy
    /// it into a production target without deciding what may be disclosed.
    ///
    private static let osLog = OSLog(subsystem: "PurchaselyExample", category: "sdk")

    private static var isInstalled = false

    /// Registers the shared sink with the SDK. Idempotent, so existing callers stay harmless.
    ///
    /// The only registration used to be `LogsView.onAppear`, which dropped every message emitted
    /// before someone opened the Logs screen — the whole of SDK start, and any purchase made
    /// before visiting that tab. Call this next to `Purchasely…start` so the buffer and the
    /// os_log mirror are armed from the first line.
    public static func install() {
        guard !isInstalled else { return }
        isInstalled = true
        Purchasely.addLogger(shared)
    }

    @Published public var logs: [SampleLoggerMessage] = [] {
        didSet {
            // Trim logs to the last `logsSizeLimit` entries if it exceeds the limit.
            if logs.count > logsSizeLimit {
                logs = Array(logs.suffix(logsSizeLimit))
            }
        }
    }

    public static var shared: SampleLogger = SampleLogger()

    private var logsSizeLimit = 50

    private init() {
        self.logs = getLogs()
    }

    /// Run `work` on the main thread (synchronously if already there). `PLYLogging.messageLogged`
    /// can be invoked from background queues; mutating the @Published `logs` off-main triggers
    /// SwiftUI's "Publishing changes from background threads is not allowed" crash.
    private func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
    }

    public func addLog(message: String) {
        let newLog = SampleLoggerMessage(message: message)
        onMain {
            self.logs.append(newLog)
            self.writeLogs(logs: self.logs)
        }
    }

    public func addLog(message: PLYMessage) {
        let newLog = SampleLoggerMessage(message: message)
        onMain {
            self.logs.append(newLog)
            self.writeLogs(logs: self.logs)
        }
    }

    public func getLogs() -> [SampleLoggerMessage] {
        let attributesString = UserDefaults.standard.string(forKey: SampleLogger.LOG_MESSAGES) ?? ""

        if let jsonData = attributesString.data(using: .utf8) {
            do {
                let logs = try JSONDecoder().decode([SampleLoggerMessage].self, from: jsonData)
                return logs
            } catch {
                print("Error decoding JSON: \(error)")
                return []
            }
        }
        print("Error decoding logs JSON")
        return []
    }

    public func clearLogs() {
        onMain {
            self.logs.removeAll()
            self.writeLogs(logs: self.logs)
        }
    }

    private func writeLogs(logs: [SampleLoggerMessage]) {
        do {
            let jsonData = try JSONEncoder().encode(logs)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                UserDefaults.standard.setValue(jsonString, forKey: SampleLogger.LOG_MESSAGES)
            }
        } catch {
            print("Error encoding array to JSON: \(error)")
        }
    }

    public func messageLogged(message: PLYMessage) {
        os_log("[%{public}@] %{public}@", log: Self.osLog, type: .default, message.logLevel, message.message)
        addLog(message: message)
    }
}

extension SampleLogger {
    fileprivate static let LOG_MESSAGES = "LOG_MESSAGES"
}

public struct SampleLoggerMessage: Decodable, Encodable, Identifiable {

    public var id = UUID()
    public let message: String
    public let logLevel: String
    public let date: Date

    public init(message: PLYMessage) {
        self.message = message.message
        self.date = message.date
        self.logLevel = message.logLevel
    }

    public init(message: String) {
        self.message = message
        self.date = Date()
        self.logLevel = "Sample"
    }
}
