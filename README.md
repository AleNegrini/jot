<div align="center">

<img src="docs/icon.png" width="128" alt="Jot icon" />

# Jot

**The fastest way to capture a TODO on your Mac.**

Hit a hotkey from anywhere, type, press Return. It's jotted.
No window to find, no app to switch to, no mouse required.

🐘 *An elephant never forgets — and neither will you.*

[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6-orange)](#requirements)
[![License](https://img.shields.io/badge/license-MIT-green)](#license)

<img src="docs/quick-add.png" width="620" alt="Jot quick-add panel" />

</div>

---

## Why Jot?

Most TODO apps make you stop what you're doing, find a window, click into a
field, then type. By then the thought is gone.

Jot lives in your menu bar and stays out of the way. A global shortcut drops a
Spotlight-style box in the middle of your screen. Type, press Return, and you're
back to work — the box even stays open so you can rattle off several items in a
row.

## Features

- ⌨️ **Global quick-add** — a system-wide hotkey opens the capture box from any app.
- ⚡️ **Multi-add** — Return saves and clears the field so you can keep typing; Esc closes.
- 📋 **Menu-bar list** — a second hotkey (or a click on the icon) shows everything at a glance.
- ✅ **Click to clear** — one click on an item removes it. Done is done.
- 🔢 **Live badge** — the menu-bar icon shows how many items are left.
- 🎛️ **Configurable shortcuts** — remap both hotkeys in Settings.
- 🚀 **Launch at login** — always ready, zero Dock clutter.
- 💾 **Local & private** — plain-text JSON on your disk. No account, no cloud, no tracking.

## Shortcuts

| Action    | Default   |
|-----------|-----------|
| Quick add | `⌃⌥Space` |
| Show list | `⌃⌥L`     |

Both are remappable in **Settings**. Inside the quick-add box: **Return** adds,
**Esc** closes.

## Install

> Jot is distributed as source. Building it yourself takes about a minute.

**Requirements:** macOS 14+ and the Xcode / Swift 6 toolchain.

```bash
git clone https://github.com/<your-username>/jot.git
cd jot
./build-app.sh --install   # builds Jot.app and copies it to /Applications
```

Then launch it:

1. **First open:** right-click `Jot` in Applications → **Open** (it's ad-hoc
   signed, not notarized, so Gatekeeper asks once).
2. **Grant Accessibility:** Jot points you to
   **System Settings → Privacy & Security → Accessibility** — enable **Jot**.
   This is what lets the global hotkeys work.
3. **Relaunch Jot** once so the shortcuts register.

Prefer to build without installing?

```bash
./build-app.sh   # produces ./Jot.app in the repo folder
```

## How it works

Jot is a lightweight menu-bar (accessory) app built with SwiftUI and AppKit.
Global hotkeys are handled by
[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).

Your list is stored as plain JSON at:

```
~/Library/Application Support/Jot/todos.json
```

Items are plain text, newest on top, duplicates allowed. Clearing an item
deletes it permanently — Jot keeps no history, by design.

## Project layout

```
Package.swift            SwiftPM manifest (depends on KeyboardShortcuts 3.x)
build-app.sh             Builds the binary and wraps it in Jot.app
make-icon.swift          Generates the app icon (.icns)
Sources/Jot/
  main.swift             Entry point (accessory app, no Dock)
  AppDelegate.swift      Status item, popover, hotkeys, badge, permission prompt
  TodoItem.swift         Model (text + internal id)
  TodoStore.swift        State + JSON persistence
  Shortcuts.swift        Hotkey names & defaults
  QuickAddPanel.swift    Spotlight-style quick-add panel
  ListView.swift         Popover UI (list + checkboxes)
  SettingsView.swift     Shortcut recorders + launch-at-login
  MenuBarIcon.swift      Menu-bar silhouette (template image)
```

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 16+ / Swift 6 toolchain (to build)

## Roadmap

A few ideas on the table — contributions welcome:

- [ ] Edit an existing item
- [ ] Reorder items
- [ ] Optional "completed" history
- [ ] Notarized release build with a downloadable `.dmg`

## License

MIT — see [LICENSE](LICENSE).

<div align="center">
<sub>Built for people who think faster than they can click.</sub>
</div>
