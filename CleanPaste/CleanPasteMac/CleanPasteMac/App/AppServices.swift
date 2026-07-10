import CleanPasteMacCore
import AppKit
import Combine
import Foundation

@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()

    let previewModel: PreviewModel
    let launchAtLoginModel: LaunchAtLoginModel
    let controller: CleanPasteController
    private let hotkeyController: HotkeyController
    private let clipboardMonitor: ClipboardMonitor
    private let targetDetector: PasteTargetDetector
    private var applicationActivationObserver: NSObjectProtocol?
    private var targetPollingTimer: Timer?
    private var lastListOutputMode: ListOutputMode?

    private init() {
        let previewModel = PreviewModel()
        self.previewModel = previewModel
        self.launchAtLoginModel = LaunchAtLoginModel()
        let targetDetector = PasteTargetDetector()
        self.targetDetector = targetDetector
        self.controller = CleanPasteController(
            targetDetector: targetDetector,
            previewModel: previewModel
        )
        self.hotkeyController = HotkeyController()
        self.clipboardMonitor = ClipboardMonitor()
    }

    func startTargetAdaptation() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        applicationActivationObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.adaptClipboardToCurrentTarget()
            }
        }
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.adaptClipboardToCurrentTarget()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        targetPollingTimer = timer
        adaptClipboardToCurrentTarget()
    }

    private func adaptClipboardToCurrentTarget() {
        let mode = targetDetector.currentListOutputMode()
        guard mode != lastListOutputMode else { return }
        lastListOutputMode = mode

        if controller.prepareClipboardForCurrentTarget() {
            clipboardMonitor.acknowledgeCurrentClipboard()
        }
    }

    func startClipboardMonitoring() {
        clipboardMonitor.start { [controller] snapshot in
            controller.cleanAutomatically(snapshot)
        }
    }

    func startHotkey() {
        let registered = hotkeyController.start { [controller] in
            controller.cleanAndPaste()
        }
        if !registered {
            previewModel.apply(
                .failed("Command-Shift-V is already in use. Menu actions still work."),
                canonicalPaste: nil
            )
        }
    }
}
