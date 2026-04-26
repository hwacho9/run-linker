import Foundation

enum RunLinkerLogger {
    static func info(_ message: String) {
        log("INFO", message)
    }

    static func warning(_ message: String) {
        log("WARN", message)
    }

    static func error(_ message: String, error: Error? = nil) {
        if let error {
            let nsError = error as NSError
            log("ERROR", "\(message) | domain=\(nsError.domain) code=\(nsError.code) message=\(nsError.localizedDescription)")
        } else {
            log("ERROR", message)
        }
    }

    static func maskedEmail(_ email: String) -> String {
        let parts = email.split(separator: "@", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return "<invalid-email>" }

        let name = parts[0]
        let maskedName: String
        if name.count <= 2 {
            maskedName = String(repeating: "*", count: max(name.count, 1))
        } else {
            maskedName = "\(name.prefix(2))***"
        }

        return "\(maskedName)@\(parts[1])"
    }

    private static func log(_ level: String, _ message: String) {
        let formattedMessage = "[RunLinker][\(level)] \(message)"
        NSLog("%@", formattedMessage)
    }
}
