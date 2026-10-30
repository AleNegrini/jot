# Jot

A tiny macOS menu-bar app for capturing TODOs fast and clearing them with a click.

- **Menu-bar only** — no Dock icon, no window clutter.
- **Global quick-add** — hit a hotkey anywhere, type, press Return, done.
- **Global show-list** — a hotkey opens the menu-bar popover.
- **Click to clear** — click an item's checkbox to delete it permanently.

## Shortcuts (defaults, configurable in Settings)

| Action    | Default    |
|-----------|------------|
| Quick add | `⌃⌥Space`  |
| Show list | `⌃⌥L`      |

Esc closes the quick-add box without saving.

## Build & install

Requires Xcode / Swift 6 toolchain.

```bash
./build-app.sh            # produces ./Jot.app
./build-app.sh --install  # also copies to /Applications
```

First launch: right-click `Jot.app` → **Open** (it's ad-hoc signed, not
notarized, so Gatekeeper asks once).

## Accessibility permission

Global hotkeys need Accessibility access. On first run Jot points you to:

**System Settings → Privacy & Security → Accessibility** → enable **Jot**.

Then quit and relaunch Jot once.

## Launch at login

Toggle in Settings (opens from the popover footer). On by default once enabled.

## Data

Stored as JSON at:

```
~/Library/Application Support/Jot/todos.json
```

Items are plain text. Newest is added on top. Duplicates are allowed. Clearing
an item deletes it permanently (no history).

## Project layout

```
Package.swift            SwiftPM manifest (depends on KeyboardShortcuts 3.x)
build-app.sh             Builds the binary and wraps it in Jot.app
Sources/Jot/
  main.swift             Entry point (accessory app, no Dock)
  AppDelegate.swift      Status item, popover, hotkeys, badge, permission prompt
  TodoItem.swift         Model (text + internal id)
  TodoStore.swift        State + JSON persistence
  Shortcuts.swift        Hotkey names & defaults
  QuickAddPanel.swift    Spotlight-style quick-add panel
  ListView.swift         Popover UI (list + checkboxes)
  SettingsView.swift     Shortcut recorders + launch-at-login
```
