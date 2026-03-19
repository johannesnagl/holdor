import AppKit
import Combine
import Foundation
import ServiceManagement

@MainActor
final class AppMonitor: ObservableObject {
    @Published var runningApps: Set<String> = []        // bundleIDs currently running
    @Published var caffeinatedApps: Set<String> = []    // bundleIDs with active caffeinate
    @Published var watchedApps: Set<WatchedApp> = []    // user-selected apps to watch

    @Published var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: "enabled"); refresh() }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLoginItem()
        }
    }

    private var caffeinateProcesses: [String: Process] = [:]  // bundleID -> Process
    private var timer: Timer?

    var anyAgentRunning: Bool { !runningApps.isEmpty }
    var isSleepPrevented: Bool { !caffeinatedApps.isEmpty }

    init() {
        UserDefaults.standard.register(defaults: [
            "enabled": true,
            "launchAtLogin": false,
        ])

        self.enabled = UserDefaults.standard.bool(forKey: "enabled")
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")

        if let data = UserDefaults.standard.data(forKey: "watchedApps"),
           let apps = try? JSONDecoder().decode(Set<WatchedApp>.self, from: data) {
            self.watchedApps = apps
        } else {
            self.watchedApps = [.claude]
        }

        refresh()
        startMonitoring()
    }

    func toggleApp(_ app: WatchedApp) {
        if watchedApps.contains(app) {
            watchedApps.remove(app)
            stopCaffeinate(for: app.bundleIdentifier)
        } else {
            watchedApps.insert(app)
        }
        saveWatchedApps()
        refresh()
    }

    func isWatching(_ app: WatchedApp) -> Bool {
        watchedApps.contains(app)
    }

    func isRunning(_ app: WatchedApp) -> Bool {
        runningApps.contains(app.bundleIdentifier)
    }

    func addCustomApp(_ app: WatchedApp) {
        watchedApps.insert(app)
        saveWatchedApps()
        refresh()
    }

    func refresh() {
        let workspace = NSWorkspace.shared
        let running = workspace.runningApplications

        var newRunning = Set<String>()
        for app in watchedApps {
            if running.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
                newRunning.insert(app.bundleIdentifier)
            }
        }
        runningApps = newRunning

        if enabled {
            // Start caffeinate for newly running watched apps
            for bundleID in runningApps where !caffeinatedApps.contains(bundleID) {
                startCaffeinate(bundleID: bundleID, runningApps: running)
            }
            // Stop caffeinate for apps no longer running
            for bundleID in caffeinatedApps where !runningApps.contains(bundleID) {
                stopCaffeinate(for: bundleID)
            }
        } else {
            // Stop all if disabled
            for bundleID in caffeinatedApps {
                stopCaffeinate(for: bundleID)
            }
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

    private func startCaffeinate(bundleID: String, runningApps: [NSRunningApplication]) {
        guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleID }) else { return }

        let pid = app.processIdentifier
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-i", "-w", "\(pid)"]

        do {
            try process.run()
            caffeinateProcesses[bundleID] = process
            caffeinatedApps.insert(bundleID)
        } catch {
            print("Failed to start caffeinate for \(bundleID): \(error)")
        }
    }

    private func stopCaffeinate(for bundleID: String) {
        caffeinateProcesses[bundleID]?.terminate()
        caffeinateProcesses.removeValue(forKey: bundleID)
        caffeinatedApps.remove(bundleID)
    }

    private func saveWatchedApps() {
        if let data = try? JSONEncoder().encode(watchedApps) {
            UserDefaults.standard.set(data, forKey: "watchedApps")
        }
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
        for (_, process) in caffeinateProcesses {
            process.terminate()
        }
    }
}
