import SwiftUI

struct MenuView: View {
    @ObservedObject var monitor: AppMonitor
    let onPreferences: () -> Void
    let onQuit: () -> Void

    private var isActive: Bool { monitor.isSleepPrevented }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 8)

            // Status rows
            VStack(spacing: 8) {
                statusRow("Watching") {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(monitor.isAgentRunning ? Color.green : Color.gray)
                            .frame(width: 6, height: 6)
                        Text(monitor.watchedApp.name)
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(6)
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

            // Actions
            VStack(spacing: 2) {
                actionButton("Preferences...") { onPreferences() }
                actionButton("Quit Holdor") { onQuit() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 300)
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

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn)
            .toggleStyle(.switch)
            .tint(.green)
            .font(.system(size: 13))
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(6)
    }
}
