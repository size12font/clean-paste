import CleanPasteMacCore
import SwiftUI

@main
struct CleanPasteMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var services: AppServices

    init() {
        _services = StateObject(wrappedValue: AppServices.shared)
    }

    var body: some Scene {
        MenuBarExtra("CleanPaste", systemImage: "doc.on.clipboard") {
            CleanPasteMenuView(
                controller: services.controller,
                previewModel: services.previewModel,
                launchAtLoginModel: services.launchAtLoginModel
            )
            .frame(minWidth: 440, idealWidth: 440, maxWidth: 440, minHeight: 470)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppServices.shared.startClipboardMonitoring()
        AppServices.shared.startTargetAdaptation()
        AppServices.shared.startHotkey()
    }
}
