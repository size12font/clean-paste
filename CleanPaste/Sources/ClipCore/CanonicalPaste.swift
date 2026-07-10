public struct CanonicalPaste: Equatable, Sendable {
    public let previewText: String
    public let sourceFlavor: PasteboardSourceFlavor
    public let observedTypeIdentifiers: [String]
    public let transformVersion: String

    public init(
        previewText: String,
        sourceFlavor: PasteboardSourceFlavor,
        observedTypeIdentifiers: [String],
        transformVersion: String
    ) {
        self.previewText = previewText
        self.sourceFlavor = sourceFlavor
        self.observedTypeIdentifiers = observedTypeIdentifiers
        self.transformVersion = transformVersion
    }
}
