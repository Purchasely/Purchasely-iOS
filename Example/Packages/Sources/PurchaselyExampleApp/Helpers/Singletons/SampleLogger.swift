//
//  SampleLogger.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 18/12/2023.
//

import Foundation
import Purchasely

class SampleLogger: PLYLogging, ObservableObject {
    
    @Published var logs: [SampleLoggerMessage] = [] {
        didSet {
            // Trim logs to the last 50 entries if it exceeds the limit
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
    
    public func addLog(message: String) {
        objectWillChange.send()
        let newLog = SampleLoggerMessage(message: message)
        logs.append(newLog)
        writeLogs(logs: logs)
    }
    
    public func addLog(message: PLYMessage) {
        objectWillChange.send()
        let newLog = SampleLoggerMessage(message: message)
        logs.append(newLog)
        writeLogs(logs: logs)
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
        objectWillChange.send()
        logs.removeAll()
        writeLogs(logs: logs)
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
    
    func messageLogged(message: PLYMessage) {
        addLog(message: message)
    }
}

extension SampleLogger {
    fileprivate static let LOG_MESSAGES = "LOG_MESSAGES"
}

struct SampleLoggerMessage: Decodable, Encodable, Identifiable {
    
    public var id = UUID()
    public let message: String
    public let logLevel: String
    public let date: Date
    
    init(message: PLYMessage) {
        self.message = message.message
        self.date = message.date
        self.logLevel = message.logLevel
    }
    
    init(message: String) {
        self.message = message
        self.date = Date()
        self.logLevel = "Sample"
    }
}
