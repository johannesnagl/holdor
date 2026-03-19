import SwiftUI

struct MenuView: View {
    @ObservedObject var monitor: AppMonitor
    let onQuit: () -> Void

    @State private var showCustomInput = false
    @State private var customName = ""
    @State private var customBundleID = ""

    private var isActive: Bool { monitor.isSleepPrevented }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(isActive ? Color.green : Color.gray)
                            .frame(width: 10, height: 10)
                        Text(isActive ? "Holding the door" : "Standing by")
                            .font(.system(size: 15, weight: .bold))
                    }
                    Text(isActive
                         ? "Sleep blocked \u{00B7} Screen lock still active"
                         : "No agent detected \u{00B7} Mac sleeps normally")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Menu {
                    Button {
                        NSWorkspace.shared.open(URL(string: "https://holdor.app")!)
                    } label: {
                        Label("Go to Website", systemImage: "globe")
                    }
                    Divider()
                    Button(action: onQuit) {
                        Label("Quit Holdor", systemImage: "power")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 8)

            // Status rows
            VStack(spacing: 8) {
                statusRow("Watching") {
                    appPicker
                }

                statusRow("Agent running") {
                    if monitor.isAgentRunning, let elapsed = monitor.elapsedTimeString {
                        Text("Yes \u{00B7} \(elapsed)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    } else {
                        Text("No")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }

                statusRow("Sleep prevented") {
                    Text(monitor.isSleepPrevented ? "Active" : "Inactive")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(monitor.isSleepPrevented ? .green : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Custom app input
            if showCustomInput {
                Divider().padding(.horizontal, 8)
                VStack(spacing: 6) {
                    TextField("App name", text: $customName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                    TextField("Bundle ID (e.g. com.example.app)", text: $customBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                    HStack {
                        Button("Cancel") {
                            showCustomInput = false
                            customName = ""
                            customBundleID = ""
                        }
                        .font(.system(size: 12))
                        Spacer()
                        Button("Watch") {
                            if !customName.isEmpty && !customBundleID.isEmpty {
                                monitor.watchedApp = WatchedApp(name: customName, bundleIdentifier: customBundleID)
                                showCustomInput = false
                                customName = ""
                                customBundleID = ""
                            }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .disabled(customName.isEmpty || customBundleID.isEmpty)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider().padding(.horizontal, 8)

            // Toggles
            VStack(spacing: 6) {
                toggleRow("Enable Holdor", isOn: $monitor.enabled)
                toggleRow("Allow display sleep", isOn: $monitor.allowDisplaySleep)
                toggleRow("Launch at login", isOn: $monitor.launchAtLogin)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.horizontal, 8)

            // Lock screen button
            Button(action: lockScreen) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text("Lock Screen")
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.green)
                .foregroundColor(.black)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

        }
        .frame(width: 300)
    }

    private var appPicker: some View {
        Menu {
            ForEach(WatchedApp.allApps, id: \.bundleIdentifier) { app in
                Button {
                    showCustomInput = false
                    monitor.watchedApp = app
                } label: {
                    HStack {
                        Text(app.name)
                        if monitor.watchedApp == app {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            Divider()
            Button("Custom...") {
                showCustomInput = true
            }
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(monitor.isAgentRunning ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
                Text(monitor.watchedApp.name)
                    .font(.system(size: 13))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.08))
            .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
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
                    .fill(isOn ? Color.green : Color.gray.opacity(0.3))
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
