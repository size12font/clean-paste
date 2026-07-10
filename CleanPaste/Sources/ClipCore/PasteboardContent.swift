import Foundation

public enum PasteboardTypeIdentifier {
    public static let plainText = "public.utf8-plain-text"
    public static let html = "public.html"
}

public struct PasteboardContent: Equatable, Sendable {
    public let textualRepresentations: [String: String]
    public let availableTypeIdentifiers: [String]

    public init(
        plainText: String? = nil,
        htmlText: String? = nil,
        availableTypeIdentifiers: [String] = []
    ) {
        var representations: [String: String] = [:]
        if let plainText {
            representations[PasteboardTypeIdentifier.plainText] = plainText
        }
        if let htmlText {
            representations[PasteboardTypeIdentifier.html] = htmlText
        }
        self.init(
            textualRepresentations: representations,
            availableTypeIdentifiers: availableTypeIdentifiers
        )
    }

    public init(
        textualRepresentations: [String: String],
        availableTypeIdentifiers: [String] = []
    ) {
        self.textualRepresentations = textualRepresentations
        self.availableTypeIdentifiers = Array(
            Set(availableTypeIdentifiers).union(textualRepresentations.keys)
        ).sorted()
    }

    public var plainText: String? {
        textualRepresentations[PasteboardTypeIdentifier.plainText]
    }

    public var htmlText: String? {
        textualRepresentations[PasteboardTypeIdentifier.html]
    }

    public func text(forTypeIdentifier typeIdentifier: String) -> String? {
        textualRepresentations[typeIdentifier]
    }
}

public struct PasteboardSourceFlavor: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let plainText = Self(rawValue: "plain_text")
    public static let html = Self(rawValue: "html")
}

public enum CleanPasteTransformError: Error, Equatable, LocalizedError {
    case noSupportedText
    case emptyOutput

    public var errorDescription: String? {
        switch self {
        case .noSupportedText:
            "Clipboard has no plain text or recoverable HTML."
        case .emptyOutput:
            "CleanPaste produced no pasteable text."
        }
    }
}
