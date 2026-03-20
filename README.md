# Holdor

**Holds the door. So your agents don't have to stop.**

A native macOS menu bar app that prevents your system from sleeping while agentic AI tools are running. Lock your screen, walk away, and your agents keep working.

## The Problem

Company security policies require locking your screen when you step away. But when macOS locks, it eventually sleeps — killing your long-running AI agents. The alternative of carrying your laptop everywhere is absurd.

## How It Works

Holdor uses macOS's built-in `caffeinate` command, tied to each app's process ID (`caffeinate -i -w <PID>`). This prevents idle sleep while allowing the display to sleep normally. When the watched app quits, the caffeinate assertion is automatically released.

## Features

- Lives in the menu bar (door icon: closed = idle, open = holding)
- Watch multiple apps simultaneously
- Auto-detects when apps launch or quit
- Add any app via native Finder file picker
- Built-in Lock Screen button
- Pause/resume protection from the gear menu
- Launch at login support
- Remembers your preferences across restarts
- Native Swift — no Electron, no runtime overhead

## Supported Apps

Built-in support for 10 apps:

- Claude Desktop
- Cursor
- Windsurf
- VS Code
- Zed
- ChatGPT
- Warp
- Terminal
- iTerm
- Ghostty

Add any other app via the "Add app..." button.

## Building

Requires Swift 5.9+ and macOS 13+.

```bash
cd app
swift build -c release
```

The binary will be at `app/.build/release/Holdor`.

### Building a DMG

```bash
./scripts/build-dmg.sh <version>
```

This creates an unsigned DMG at `dist/Holdor-<version>-arm64.dmg`.

To build a **signed and notarized** DMG:

```bash
SIGN_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" \
NOTARIZE_PROFILE="your-keychain-profile" \
./scripts/build-dmg.sh <version>
```

Setting up code signing requires:
1. An [Apple Developer Program](https://developer.apple.com/programs/) membership
2. A **Developer ID Application** certificate
3. A notarization keychain profile: `xcrun notarytool store-credentials "your-keychain-profile" --apple-id "you@example.com" --team-id "TEAM_ID"`

## Running

```bash
./app/.build/release/Holdor
```

Or copy it to `/Applications` and add to Login Items.

## Support

If Holdor saves you from carrying your laptop around, [buy me a pasta](https://paypal.me/jollife).

## License

MIT
