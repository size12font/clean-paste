import AppKit
import Foundation

public protocol PasteboardReading: Sendable {
    func snapshot() -> PasteboardSnapshot
}

public final class PasteboardReader: PasteboardReading, @unchecked Sendable {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public func snapshot() -> PasteboardSnapshot {
        let types = pasteboard.types ?? []
        var textualRepresentations: [String: String] = [:]
        for type in types {
            textualRepresentations[type.rawValue] = pasteboard.string(forType: type)
        }

        return PasteboardSnapshot(
            changeCount: pasteboard.changeCount,
            typeIdentifiers: types.map(\.rawValue),
            textualRepresentations: textualRepresentations
        )
    }
}
