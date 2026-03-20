import SwiftUI

// Website color palette — Raw Control Room
extension Color {
    static let holdorAmber = Color(red: 229/255, green: 149/255, blue: 0/255)       // #e59500
    static let holdorAmberDim = Color(red: 229/255, green: 149/255, blue: 0/255).opacity(0.1)
    static let holdorGreen = Color(red: 34/255, green: 197/255, blue: 94/255)        // #22c55e
}

struct MenuView: View {
    @ObservedObject var monitor: AppMonitor
    let onQuit: () -> Void


    private var isActive: Bool { monitor.isSleepPrevented }

    private var headerSubtitle: String {
        if !monitor.enabled {
            return "Protection disabled // Mac sleeps normally"
        }
        let running = monitor.watchedRunningCount
        let watched = monitor.watchedApps.count
        if watched == 0 {
            return "No apps selected // Add apps to watch"
        }
        if running == 0 {
            return "0 of \(watched) watched app\(watched == 1 ? "" : "s") running"
        }
        let mode = monitor.extendedMode ? "Extended" : "Regular"
        return "Sleep blocked (\(mode)) // Screen lock still active"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isActive ? Color.holdorGreen : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(isActive ? "Holding the door" : "Standing by")
                            .font(.system(size: 15, weight: .bold))
                    }
                    Spacer()
                    Menu {
                        Button {
                            monitor.enabled.toggle()
                        } label: {
                            Label(monitor.enabled ? "Pause protection" : "Resume protection",
                                  systemImage: monitor.enabled ? "pause.circle" : "play.circle")
                        }
                        Button {
                            monitor.launchAtLogin.toggle()
                        } label: {
                            Label(monitor.launchAtLogin ? "Disable launch at login" : "Launch at login",
                                  systemImage: monitor.launchAtLogin ? "checkmark.circle" : "arrow.clockwise")
                        }
                        Button {
                            monitor.extendedMode.toggle()
                        } label: {
                            Label(monitor.extendedMode ? "Disable extended mode" : "Extended mode (prevent lid sleep)",
                                  systemImage: monitor.extendedMode ? "bolt.circle.fill" : "bolt.circle")
                        }
                        Divider()
                        Button {
                            NSWorkspace.shared.open(URL(string: "https://holdor.app")!)
                        } label: {
                            Label("Go to Website", systemImage: "globe")
                        }
                        Button {
                            NSWorkspace.shared.open(URL(string: "https://paypal.me/jollife")!)
                        } label: {
                            Label("Buy me a Pasta", systemImage: "fork.knife")
                        }
                        Divider()
                        Button(action: onQuit) {
                            Label("Quit Holdor", systemImage: "power")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
                Text(headerSubtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 8)

            // Watching section
            VStack(alignment: .leading, spacing: 8) {
                Text("Watching")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                ForEach(monitor.installedBuiltInApps, id: \.bundleIdentifier) { app in
                    appRow(app, removable: false)
                }

                ForEach(customApps, id: \.bundleIdentifier) { app in
                    appRow(app, removable: true)
                }

                Button(action: pickApp) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Add app...")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Paused warning
            if !monitor.enabled {
                HStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.holdorAmber)
                    Text("Protection paused")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.holdorAmber)
                    Spacer()
                    Button("Resume") {
                        monitor.enabled = true
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.holdorAmber)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.holdorAmberDim)
            }

            Divider().padding(.horizontal, 8)

            // Lock screen button
            Button(action: lockScreen) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text(monitor.enabled ? "Lock Screen" : "Lock Screen (unprotected)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(monitor.enabled ? Color.holdorAmber : Color.holdorAmber.opacity(0.5))
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

        }
        .frame(width: 300)
    }

    private func pickApp() {
        // Dispatch async so the popover can close first, then show the panel
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)

            let panel = NSOpenPanel()
            panel.title = "Choose an application"
            panel.allowedContentTypes = [.application]
            panel.allowsMultipleSelection = false
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.level = .floating

            guard panel.runModal() == .OK, let url = panel.url else { return }

            let bundle = Bundle(url: url)
            guard let bundleID = bundle?.bundleIdentifier else { return }
            let name = bundle?.infoDictionary?["CFBundleName"] as? String
                ?? bundle?.infoDictionary?["CFBundleDisplayName"] as? String
                ?? url.deletingPathExtension().lastPathComponent

            let app = WatchedApp(name: name, bundleIdentifier: bundleID)
            self.monitor.addCustomApp(app)
        }
    }

    private var customApps: [WatchedApp] {
        let builtInIDs = Set(WatchedApp.allApps.map(\.bundleIdentifier))
        return monitor.watchedApps.filter { !builtInIDs.contains($0.bundleIdentifier) }.sorted { $0.name < $1.name }
    }

    private func appRow(_ app: WatchedApp, removable: Bool) -> some View {
        HStack {
            Button {
                monitor.toggleApp(app)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: monitor.isWatching(app) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(monitor.isWatching(app) ? .holdorAmber : .secondary)
                        .font(.system(size: 14))
                    Text(app.name)
                        .font(.system(size: 13))
                }
            }
            .buttonStyle(.plain)
            Spacer()
            if removable {
                Button {
                    monitor.removeCustomApp(app)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove \(app.name)")
            }
            Text(monitor.isRunning(app) ? "Running" : "Not Running")
                .font(.system(size: 11))
                .foregroundColor(monitor.isRunning(app) ? .holdorGreen : .secondary)
        }
    }

    private func statusRow<Content: View>(_ label: String, @ViewBuilder value: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            value()
        }
    }

    private func lockScreen() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["displaysleepnow"]
        try? process.run()
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(GreenSwitchStyle())
                .labelsHidden()
        }
    }

}

struct GreenSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        let isOn = configuration.isOn
        HStack {
            configuration.label
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.holdorAmber : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 24)
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 1)
                    .frame(width: 20, height: 20)
                    .padding(2)
            }
            .animation(.easeInOut(duration: 0.15), value: isOn)
            .onTapGesture { configuration.isOn.toggle() }
        }
    }
}
