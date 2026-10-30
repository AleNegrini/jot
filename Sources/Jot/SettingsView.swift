import SwiftUI
import KeyboardShortcuts
import ServiceManagement

/// Settings window: configure the two global hotkeys and launch-at-login.
struct SettingsView: View {
    @State private var launchAtLogin = LaunchAtLogin.isEnabled

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2.bold())

            GroupBox("Global Shortcuts") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Quick add")
                            .frame(width: 110, alignment: .leading)
                        KeyboardShortcuts.Recorder(for: .quickAdd)
                    }
                    HStack {
                        Text("Show list")
                            .frame(width: 110, alignment: .leading)
                        KeyboardShortcuts.Recorder(for: .showList)
                    }
                }
                .padding(8)
            }

            GroupBox("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LaunchAtLogin.isEnabled = newValue
                    }
                    .padding(8)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 380, height: 300)
    }
}

/// Thin wrapper around SMAppService for the login-item toggle.
enum LaunchAtLogin {
    static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("Jot: launch-at-login toggle failed: \(error)")
            }
        }
    }
}
