import AppKit
import SwiftUI

@main
struct ZhzSwitchApp: App {
    var body: some Scene {
        WindowGroup("zhz-switch", id: "main") {
            MainWindowView()
        }
        .defaultSize(width: 1_180, height: 720)
        .windowResizability(.contentMinSize)

        MenuBarExtra("zhz swich", image: "MenuBarLogo") {
            MenuContentView()
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct MenuContentView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Section {
            HStack(spacing: 10) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("zhz swich")
                        .font(.headline)
                    Text("管理多个供应商地址")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }

        Section {
            Button {
                openWindow(id: "main")
            } label: {
                Label("打开主窗口", systemImage: "macwindow")
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
            }
        }
    }
}
