@_implementationOnly import _SentryPrivate
import Foundation

@objc
class SentryLog: NSObject {
    
    static private(set) var isDebug = true
    static private(set) var diagnosticLevel = SentryLevel.error

    /**
     * Threshold log level to always log, regardless of the current configuration
     */
    static let alwaysLevel = SentryLevel.fatal
    private static var logOutput = SentryLogOutput()
    private static var logConfigureLock = NSLock()

    @objc
    static func configure(_ isDebug: Bool, diagnosticLevel: SentryLevel) {
        logConfigureLock.synchronized {
            self.isDebug = isDebug
            self.diagnosticLevel = diagnosticLevel
        }
        SentryAsyncLogWrapper.initializeAsyncLogFile()
    }
    
    @objc
    static func log(message: String, andLevel level: SentryLevel) {
        guard willLog(atLevel: level) else { return }
        logOutput.log("[Sentry] [\(level)] \(message)")
    }

    /**
     * @return @c YES if the current logging configuration will log statements at the current level,
     * @c NO if not.
     */
    @objc
    static func willLog(atLevel level: SentryLevel) -> Bool {
        if level == .none {
            return false
        }
        if level.rawValue >= alwaysLevel.rawValue {
            return true
        }
        return isDebug && level.rawValue >= diagnosticLevel.rawValue
    }
 
    #if SENTRY_TEST || SENTRY_TEST_CI
    
    static func setOutput(_ output: SentryLogOutput) {
        logOutput = output
    }
    
    static func getOutput() -> SentryLogOutput {
        return logOutput
    }
    
    #endif
}

extension SentryLog {
    private static func log(level: SentryLevel, message: String, file: String, line: Int) {
        guard willLog(atLevel: level) else { return }
        let path = file as NSString
        let fileName = (path.lastPathComponent as NSString).deletingPathExtension
        log(message: "[\(fileName):\(line)] \(message)", andLevel: level)
    }
    
    static func debug(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .debug, message: message, file: file, line: line)
    }
    
    static func info(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .info, message: message, file: file, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .warning, message: message, file: file, line: line)
    }
    
    static func error(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .error, message: message, file: file, line: line)
    }
    
    static func fatal(_ message: String, file: String = #file, line: Int = #line) {
        log(level: .fatal, message: message, file: file, line: line)
    }
}
