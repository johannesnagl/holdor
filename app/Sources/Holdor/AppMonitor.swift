import AppKit
import Combine
import Foundation

@MainActor
final class AppMonitor: ObservableObject {
    @Published var runningStates: [String: Bool] = [:]  // app.id -> is running
    @Published var caffeinatedApps: Set<String> = []     // app.id set
    @Published var enabledApps: Set<String> = []         // user-toggled app.id set

    private var caffeinateProcesses: [String: Process] = [:]  // app.id -> caffeinate Process
    private var timer: Timer?

    let apps: [AgenticApp]

    init(apps: [AgenticApp] = AgenticApp.builtIn) {
        self.apps = apps
        loadPreferences()
        refresh()
        startMonitoring()
    }

    func toggle(app: AgenticApp) {
        if enabledApps.contains(app.id) {
            enabledApps.remove(app.id)
            stopCaffeinate(for: app)
        } else {
            enabledApps.insert(app.id)
            startCaffeinateIfRunning(for: app)
        }
        savePreferences()
    }

    func refresh() {
        let workspace = NSWorkspace.shared
        let running = workspace.runningApplications

        for app in apps {
            let isRunning = running.contains { $0.bundleIdentifier == app.bundleIdentifier }
            runningStates[app.id] = isRunning

            if enabledApps.contains(app.id) {
                if isRunning && !caffeinatedApps.contains(app.id) {
                    startCaffeinate(for: app, runningApps: running)
                } else if !isRunning && caffeinatedApps.contains(app.id) {
                    stopCaffeinate(for: app)
                }
            }
        }
    }

    var activeCaffeinateCount: Int {
        caffeinatedApps.count
    }

    // MARK: - Private

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    private func startCaffeinateIfRunning(for app: AgenticApp) {
        let workspace = NSWorkspace.shared
        let running = workspace.runningApplications
        if running.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
            startCaffeinate(for: app, runningApps: running)
        }
    }

    private func startCaffeinate(for app: AgenticApp, runningApps: [NSRunningApplication]) {
        guard let runningApp = runningApps.first(where: { $0.bundleIdentifier == app.bundleIdentifier }) else {
            return
        }

        let pid = runningApp.processIdentifier

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = ["-i", "-w", "\(pid)"]

        do {
            try process.run()
            caffeinateProcesses[app.id] = process
            caffeinatedApps.insert(app.id)
        } catch {
            print("Failed to start caffeinate for \(app.name): \(error)")
        }
    }

    private func stopCaffeinate(for app: AgenticApp) {
        if let process = caffeinateProcesses[app.id] {
            process.terminate()
            caffeinateProcesses.removeValue(forKey: app.id)
        }
        caffeinatedApps.remove(app.id)
    }

    private func savePreferences() {
        UserDefaults.standard.set(Array(enabledApps), forKey: "enabledApps")
    }

    private func loadPreferences() {
        if let saved = UserDefaults.standard.stringArray(forKey: "enabledApps") {
            enabledApps = Set(saved)
        }
    }

    deinit {
        timer?.invalidate()
        for (_, process) in caffeinateProcesses {
            process.terminate()
        }
    }
}
