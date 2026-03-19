import AppKit
import Combine
import SwiftUI

@main
struct HoldorApp: App {
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
    private var popover: NSPopover!
    private let monitor = AppMonitor()
    private var cancellables = Set<AnyCancellable>()
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "door.left.hand.closed", accessibilityDescription: "Holdor")
            button.action = #selector(togglePopover)
            button.target = self
        }

        let menuView = MenuView(
            monitor: monitor,
            onPreferences: { [weak self] in self?.closePopover() },
            onQuit: { NSApp.terminate(nil) }
        )

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: menuView)

        monitor.$isSleepPrevented
            .receive(on: RunLoop.main)
            .sink { [weak self] active in self?.updateIcon(active: active) }
            .store(in: &cancellables)

        updateIcon(active: monitor.isSleepPrevented)
    }

    private func updateIcon(active: Bool) {
        guard let button = statusItem.button else { return }
        let symbolName = active ? "door.left.hand.open" : "door.left.hand.closed"
        var config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        if active {
            config = config.applying(.init(paletteColors: [.systemGreen]))
        }
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Holdor")?
            .withSymbolConfiguration(config)
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            monitor.refresh()
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}
