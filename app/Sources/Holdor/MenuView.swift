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

            // Watching section
            VStack(alignment: .leading, spacing: 8) {
                Text("Watching")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                ForEach(WatchedApp.allApps, id: \.bundleIdentifier) { app in
                    appRow(app)
                }

                // Custom watched apps (not in allApps)
                ForEach(customApps, id: \.bundleIdentifier) { app in
                    appRow(app)
                }

                Button {
                    showCustomInput = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                        Text("Add custom app")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
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
                        Button("Add") {
                            if !customName.isEmpty && !customBundleID.isEmpty {
                                monitor.addCustomApp(WatchedApp(name: customName, bundleIdentifier: customBundleID))
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
                VStack(alignment: .leading, spacing: 2) {
                    toggleRow("Enable Holdor", isOn: $monitor.enabled)
                    Text(monitor.enabled
                         ? "Agents keep running when you lock the screen"
                         : "Mac sleeps normally, agents may be interrupted")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
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

    private var customApps: [WatchedApp] {
        let builtInIDs = Set(WatchedApp.allApps.map(\.bundleIdentifier))
        return monitor.watchedApps.filter { !builtInIDs.contains($0.bundleIdentifier) }.sorted { $0.name < $1.name }
    }

    private func appRow(_ app: WatchedApp) -> some View {
        HStack {
            Button {
                monitor.toggleApp(app)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: monitor.isWatching(app) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(monitor.isWatching(app) ? .green : .secondary)
                        .font(.system(size: 14))
                    Text(app.name)
                        .font(.system(size: 13))
                }
            }
            .buttonStyle(.plain)
            Spacer()
            if monitor.isWatching(app) {
                Circle()
                    .fill(monitor.isRunning(app) ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
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
