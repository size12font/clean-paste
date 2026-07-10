public enum TargetCapabilityKind: String, Codable, CaseIterable, Hashable, Sendable {
    case nativeText = "native_text"
    case webTextarea = "web_textarea"
    case webContenteditable = "web_contenteditable"
    case richComposer = "rich_composer"
}

public struct TargetCapability: Codable, Equatable, Hashable, Sendable {
    public let kind: TargetCapabilityKind
    public let acceptsPlainText: Bool
    public let preservesNewlines: Bool
    public let preservesListMarkers: Bool
    public let maximumLength: Int?
    public let knownMutations: [String]

    public init(
        kind: TargetCapabilityKind,
        acceptsPlainText: Bool,
        preservesNewlines: Bool,
        preservesListMarkers: Bool,
        maximumLength: Int?,
        knownMutations: [String]
    ) {
        self.kind = kind
        self.acceptsPlainText = acceptsPlainText
        self.preservesNewlines = preservesNewlines
        self.preservesListMarkers = preservesListMarkers
        self.maximumLength = maximumLength
        self.knownMutations = knownMutations
    }

    public static let releaseGate: [Self] = TargetCapabilityKind.allCases.map { kind in
        let knownMutations: [String]
        switch kind {
        case .webContenteditable:
            knownMutations = ["A host may append one trailing newline; visible structure must otherwise match."]
        case .richComposer:
            knownMutations = ["A host may apply visual styling while preserving canonical characters and structure."]
        default:
            knownMutations = []
        }

        return Self(
            kind: kind,
            acceptsPlainText: true,
            preservesNewlines: true,
            preservesListMarkers: true,
            maximumLength: nil,
            knownMutations: knownMutations
        )
    }
}
