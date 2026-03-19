import Foundation

struct WatchedApp: Codable, Hashable {
    let name: String
    let bundleIdentifier: String

    static let claude = WatchedApp(name: "Claude", bundleIdentifier: "com.anthropic.claudefordesktop")
    static let cursor = WatchedApp(name: "Cursor", bundleIdentifier: "com.todesktop.230313mzl4w4u92")
    static let windsurf = WatchedApp(name: "Windsurf", bundleIdentifier: "com.codeium.windsurf")

    static let allApps: [WatchedApp] = [.claude, .cursor, .windsurf]
}
