import AppKit
import Foundation

public enum PasteboardWriteError: Error, Equatable, LocalizedError {
    case emptyText
    case writeFailed

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            "CleanPaste refused to clear the clipboard because output was empty."
        case .writeFailed:
            "CleanPaste could not write clean content to the clipboard."
        }
    }
}

public protocol CleanPasteboardWriting: Sendable {
    func write(_ text: String, listMode: ListOutputMode) throws
}

public extension CleanPasteboardWriting {
    func write(_ text: String) throws {
        try write(text, listMode: .semanticLists)
    }
}

public final class CleanPasteboardWriter: CleanPasteboardWriting, @unchecked Sendable {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func write(_ text: String, listMode: ListOutputMode) throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PasteboardWriteError.emptyText
        }

        let item = NSPasteboardItem()
        guard item.setString(text, forType: .string) else {
            throw PasteboardWriteError.writeFailed
        }

        if listMode == .semanticLists,
           let html = SemanticHTMLRenderer.renderIfNeeded(text),
           !item.setString(html, forType: .html) {
            throw PasteboardWriteError.writeFailed
        }

        pasteboard.clearContents()

        guard pasteboard.writeObjects([item]) else {
            throw PasteboardWriteError.writeFailed
        }
    }
}
