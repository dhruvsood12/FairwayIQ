import Foundation

enum DebugLogger {
    static func log(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[FairwayIQ] \(message())")
        #endif
    }

    static func error(_ message: @autoclosure () -> String, error: Error? = nil) {
        #if DEBUG
        if let error {
            print("[FairwayIQ][Error] \(message()) :: \(error)")
        } else {
            print("[FairwayIQ][Error] \(message())")
        }
        #endif
    }
}

