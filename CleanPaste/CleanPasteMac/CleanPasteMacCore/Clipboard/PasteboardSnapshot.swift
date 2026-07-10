import ClipCore
import Foundation

public struct PasteboardSnapshot: Equatable, Sendable {
    public var changeCount: Int
    public var typeIdentifiers: [String]
    public var textualRepresentations: [String: String]

    public init(
        changeCount: Int,
        typeIdentifiers: [String],
        plainText: String? = nil,
        htmlText: String? = nil
    ) {
        var representations: [String: String] = [:]
        if let plainText {
            representations[PasteboardTypeIdentifier.plainText] = plainText
        }
        if let htmlText {
            representations[PasteboardTypeIdentifier.html] = htmlText
        }
        self.init(
            changeCount: changeCount,
            typeIdentifiers: typeIdentifiers,
            textualRepresentations: representations
        )
    }

    public init(
        changeCount: Int,
        typeIdentifiers: [String],
        textualRepresentations: [String: String]
    ) {
        self.changeCount = changeCount
        self.typeIdentifiers = Array(
            Set(typeIdentifiers).union(textualRepresentations.keys)
        ).sorted()
        self.textualRepresentations = textualRepresentations
    }

    public var content: PasteboardContent {
        PasteboardContent(
            textualRepresentations: textualRepresentations,
            availableTypeIdentifiers: typeIdentifiers
        )
    }
}
