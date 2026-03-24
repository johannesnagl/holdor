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
            onQuit: { NSApp.terminate(nil) }
        )

        let hostingController = NSHostingController(rootView: menuView)
        hostingController.view.setFrameSize(hostingController.sizeThatFits(in: NSSize(width: 300, height: 10000)))

        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 0)
        popover.behavior = .transient
        popover.contentViewController = hostingController

        Publishers.CombineLatest(monitor.$caffeinatedApps, monitor.$enabled)
            .receive(on: RunLoop.main)
            .sink { [weak self] caffeinated, enabled in
                self?.updateIcon(active: !caffeinated.isEmpty && enabled)
            }
            .store(in: &cancellables)

        updateIcon(active: monitor.isSleepPrevented && monitor.enabled)
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
                popover.contentViewController?.view.window?.makeKey()
            }
            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.closePopover()
            }
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
