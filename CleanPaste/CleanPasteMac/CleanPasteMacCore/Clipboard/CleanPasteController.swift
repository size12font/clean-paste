import ClipCore
import Combine
import Foundation

public enum CleanPasteActionResult: Equatable, Sendable {
    case cleaned(String)
    case pasted(String)
    case needsManualPaste(String)
    case failed(String)

    public var previewText: String? {
        switch self {
        case .cleaned(let text), .pasted(let text), .needsManualPaste(let text):
            text
        case .failed:
            nil
        }
    }
}

@MainActor
public final class CleanPasteController: ObservableObject {
    private let reader: PasteboardReading
    private let writer: CleanPasteboardWriting
    private let pasteSender: PasteSending
    private let permissionChecker: AccessibilityPermissionChecking
    private let targetDetector: PasteTargetDetecting
    private var didRequestAccessibilityAccess = false

    public let previewModel: PreviewModel

    public init(
        reader: PasteboardReading = PasteboardReader(),
        writer: CleanPasteboardWriting = CleanPasteboardWriter(),
        pasteSender: PasteSending = SyntheticPasteSender(),
        permissionChecker: AccessibilityPermissionChecking = AccessibilityPermissionModel(),
        targetDetector: PasteTargetDetecting = PasteTargetDetector(),
        previewModel: PreviewModel = PreviewModel()
    ) {
        self.reader = reader
        self.writer = writer
        self.pasteSender = pasteSender
        self.permissionChecker = permissionChecker
        self.targetDetector = targetDetector
        self.previewModel = previewModel
    }

    @discardableResult
    public func cleanClipboardNow() -> CleanPasteActionResult {
        clean(snapshot: reader.snapshot(), reportFailure: true)
    }

    @discardableResult
    public func cleanAutomatically(_ snapshot: PasteboardSnapshot) -> CleanPasteActionResult {
        clean(snapshot: snapshot, reportFailure: false)
    }

    private func clean(
        snapshot: PasteboardSnapshot,
        reportFailure: Bool
    ) -> CleanPasteActionResult {
        do {
            let result = try CleanPasteTransform.clean(snapshot.content)
            try writer.write(
                result.previewText,
                listMode: targetDetector.currentListOutputMode()
            )
            previewModel.apply(.cleaned, canonicalPaste: result)
            return .cleaned(result.previewText)
        } catch {
            let message = error.localizedDescription
            if reportFailure {
                previewModel.apply(.failed(message), canonicalPaste: nil)
            }
            return .failed(message)
        }
    }

    @discardableResult
    public func prepareClipboardForCurrentTarget() -> Bool {
        guard let canonicalPaste = previewModel.canonicalPaste else { return false }

        do {
            try writer.write(
                canonicalPaste.previewText,
                listMode: targetDetector.currentListOutputMode()
            )
            return true
        } catch {
            previewModel.apply(.failed(error.localizedDescription), canonicalPaste: nil)
            return false
        }
    }

    @discardableResult
    public func cleanAndPaste() -> CleanPasteActionResult {
        let cleanResult = cleanClipboardNow()
        guard let previewText = cleanResult.previewText else {
            return cleanResult
        }

        guard permissionChecker.isTrusted else {
            if !didRequestAccessibilityAccess {
                didRequestAccessibilityAccess = true
                permissionChecker.requestAccessPrompt()
            }
            previewModel.apply(.manualPasteRequired, canonicalPaste: previewModel.canonicalPaste)
            return .needsManualPaste(previewText)
        }

        if pasteSender.sendPaste() {
            previewModel.apply(.pasted, canonicalPaste: previewModel.canonicalPaste)
            return .pasted(previewText)
        }

        previewModel.apply(.manualPasteRequired, canonicalPaste: previewModel.canonicalPaste)
        return .needsManualPaste(previewText)
    }
}
