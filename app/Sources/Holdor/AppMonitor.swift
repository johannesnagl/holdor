import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppMonitor: ObservableObject {
    @Published var isAgentRunning = false
    @Published var isSleepPrevented = false
    @Published var agentStartTime: Date?

    @Published var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: "enabled"); refresh() }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }
    @Published var watchedApp: WatchedApp {
        didSet {
            if let data = try? JSONEncoder().encode(watchedApp) {
                UserDefaults.standard.set(data, forKey: "watchedApp")
            }
            stopCaffeinate()
            refresh()
        }
    }

    private var caffeinateProcess: Process?
    private var timer: Timer?

    init() {
        UserDefaults.standard.register(defaults: [
            "enabled": true,
            "launchAtLogin": false,
        ])

        self.enabled = UserDefaults.standard.bool(forKey: "enabled")
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")

        if let data = UserDefaults.standard.data(forKey: "watchedApp"),
           let app = try? JSONDecoder().decode(WatchedApp.self, from: data) {
            self.watchedApp = app
        } else {
            self.watchedApp = .claude
        }

        refresh()
        startMonitoring()
    }

    var elapsedTimeString: String? {
        guard let start = agentStartTime else { return nil }
        let seconds = Int(Date().timeIntervalSince(start))
        if seconds < 60 { return "\(seconds) sec" }
        return "\(seconds / 60) min"
    }

    func refresh() {
        let workspace = NSWorkspace.shared
        let running = workspace.runningApplications
        let wasRunning = isAgentRunning
        isAgentRunning = running.contains { $0.bundleIdentifier == watchedApp.bundleIdentifier }

        if isAgentRunning && !wasRunning {
            agentStartTime = Date()
        } else if !isAgentRunning && wasRunning {
            agentStartTime = nil
        }

        if enabled && isAgentRunning && !isSleepPrevented {
            startCaffeinate(runningApps: running)
        } else if (!enabled || !isAgentRunning) && isSleepPrevented {
            stopCaffeinate()
        }
    }

    // MARK: - Private

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func startCaffeinate(runningApps: [NSRunningApplication]) {
        guard let app = runningApps.first(where: { $0.bundleIdentifier == watchedApp.bundleIdentifier }) else {
            return
        }

        let pid = app.processIdentifier

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-i", "-w", "\(pid)"]

        do {
            try process.run()
            caffeinateProcess = process
            isSleepPrevented = true
        } catch {
            print("Failed to start caffeinate: \(error)")
        }
    }

    private func stopCaffeinate() {
        caffeinateProcess?.terminate()
        caffeinateProcess = nil
        isSleepPrevented = false
    }

    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }

    deinit {
        timer?.invalidate()
        caffeinateProcess?.terminate()
    }
}
