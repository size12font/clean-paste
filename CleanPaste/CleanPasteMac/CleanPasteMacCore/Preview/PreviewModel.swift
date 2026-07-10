import Combine
import ClipCore
import Foundation

public enum CleanPasteStatus: Equatable, Sendable {
    case idle
    case cleaned
    case pasted
    case manualPasteRequired
    case failed(String)

    public var message: String {
        switch self {
        case .idle:
            "Copy text. CleanPaste cleans it automatically."
        case .cleaned:
            "Clipboard cleaned."
        case .pasted:
            "Clean text pasted."
        case .manualPasteRequired:
            "Clipboard cleaned. Press Command-V."
        case .failed(let message):
            message
        }
    }
}

@MainActor
public final class PreviewModel: ObservableObject {
    @Published public private(set) var canonicalPaste: CanonicalPaste?
    @Published public private(set) var status: CleanPasteStatus

    public var previewText: String {
        canonicalPaste?.previewText ?? ""
    }

    public init(canonicalPaste: CanonicalPaste? = nil, status: CleanPasteStatus = .idle) {
        self.canonicalPaste = canonicalPaste
        self.status = status
    }

    public func apply(_ status: CleanPasteStatus, canonicalPaste: CanonicalPaste?) {
        self.status = status
        if let canonicalPaste {
            self.canonicalPaste = canonicalPaste
        }
    }
}
