# AgentGuard

**Keep your AI agents awake.**

A native macOS menu bar app that prevents your system from sleeping while agentic AI tools (Claude Desktop, Cursor, Windsurf) are running. Lock your screen, walk away, and your agents keep working.

## The Problem

Company security policies require locking your screen when you step away. But when macOS locks, it eventually sleeps — killing your long-running AI agents. The alternative of carrying your laptop everywhere is absurd.

## How It Works

AgentGuard uses macOS's built-in `caffeinate` command, tied to each app's process ID (`caffeinate -i -w <PID>`). This prevents idle sleep while allowing the display to sleep normally. When the watched app quits, the caffeinate assertion is automatically released.

## Features

- Lives in the menu bar (no dock icon, no windows)
- Auto-detects supported running apps
- Toggle caffeination per app
- Remembers your preferences across restarts
- Native Swift — no Electron, no runtime overhead

## Supported Apps

- Claude Desktop
- Cursor
- Windsurf

## Building

Requires Swift 5.9+ and macOS 13+.

```bash
cd app
swift build -c release
```

The binary will be at `app/.build/release/AgentGuard`.

## Running

```bash
./app/.build/release/AgentGuard
```

Or copy it to `/Applications` and add to Login Items.

## License

MIT
