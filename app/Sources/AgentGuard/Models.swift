import Foundation

struct AgenticApp: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let processName: String

    static let builtIn: [AgenticApp] = [
        AgenticApp(
            id: "claude-desktop",
            name: "Claude Desktop",
            bundleIdentifier: "com.anthropic.claudefordesktop",
            processName: "Claude"
        ),
        AgenticApp(
            id: "cursor",
            name: "Cursor",
            bundleIdentifier: "com.todesktop.230313mzl4w4u92",
            processName: "Cursor"
        ),
        AgenticApp(
            id: "windsurf",
            name: "Windsurf",
            bundleIdentifier: "com.codeium.windsurf",
            processName: "Windsurf"
        ),
    ]
}
