import Foundation

struct WatchedApp: Codable, Hashable {
    let name: String
    let bundleIdentifier: String

    static let claude = WatchedApp(name: "Claude", bundleIdentifier: "com.anthropic.claudefordesktop")
    static let cursor = WatchedApp(name: "Cursor", bundleIdentifier: "com.todesktop.230313mzl4w4u92")
    static let windsurf = WatchedApp(name: "Windsurf", bundleIdentifier: "com.codeium.windsurf")
    static let vscode = WatchedApp(name: "VS Code", bundleIdentifier: "com.microsoft.VSCode")
    static let zed = WatchedApp(name: "Zed", bundleIdentifier: "dev.zed.Zed")
    static let chatgpt = WatchedApp(name: "ChatGPT", bundleIdentifier: "com.openai.chat")
    static let warp = WatchedApp(name: "Warp", bundleIdentifier: "dev.warp.Warp-Stable")
    static let terminal = WatchedApp(name: "Terminal", bundleIdentifier: "com.apple.Terminal")
    static let iterm = WatchedApp(name: "iTerm", bundleIdentifier: "com.googlecode.iterm2")
    static let ghostty = WatchedApp(name: "Ghostty", bundleIdentifier: "com.mitchellh.ghostty")

    static let allApps: [WatchedApp] = [.claude, .cursor, .windsurf, .vscode, .zed, .chatgpt, .warp, .terminal, .iterm, .ghostty]
}
