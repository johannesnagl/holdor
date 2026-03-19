import AppKit
import Combine
import SwiftUI

@main
struct AgentGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover?
    private let monitor = AppMonitor()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "AgentGuard")
            button.action = #selector(toggleMenu)
            button.target = self
        }

        updateMenu()

        monitor.$caffeinatedApps
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateMenu() }
            .store(in: &cancellables)
        monitor.$runningStates
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateMenu() }
            .store(in: &cancellables)
    }

    @objc private func toggleMenu() {
        updateMenu()
        statusItem.button?.performClick(nil)
    }

    private func updateMenu() {
        let menu = NSMenu()

        let headerItem = NSMenuItem(title: "AgentGuard", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        headerItem.attributedTitle = NSAttributedString(
            string: "AgentGuard",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        menu.addItem(headerItem)

        let count = monitor.activeCaffeinateCount
        let statusText = count > 0
            ? "\(count) app\(count == 1 ? "" : "s") caffeinated"
            : "No apps caffeinated"
        let statusMenuItem = NSMenuItem(title: statusText, action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        for app in monitor.apps {
            let isRunning = monitor.runningStates[app.id] ?? false
            let isEnabled = monitor.enabledApps.contains(app.id)
            let isCaffeinated = monitor.caffeinatedApps.contains(app.id)

            var title = app.name
            if !isRunning {
                title += " (not running)"
            } else if isCaffeinated {
                title += " (caffeinated)"
            }

            let item = NSMenuItem(title: title, action: #selector(appToggled(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = app.id
            item.state = isEnabled ? .on : .off
            item.isEnabled = true
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit AgentGuard", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusItem.menu = menu

        if let button = self.statusItem.button {
            let symbolName = count > 0 ? "cup.and.saucer.fill" : "cup.and.saucer"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "AgentGuard")
        }
    }

    @objc private func appToggled(_ sender: NSMenuItem) {
        guard let appId = sender.representedObject as? String,
              let app = monitor.apps.first(where: { $0.id == appId }) else { return }
        monitor.toggle(app: app)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
