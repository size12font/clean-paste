import AppKit
import CoreGraphics
import Foundation

public enum ListOutputMode: Equatable, Sendable {
    case literalMarkers
    case semanticLists
}

@MainActor
public protocol PasteTargetDetecting: Sendable {
    func currentListOutputMode() -> ListOutputMode
}

@MainActor
public final class PasteTargetDetector: PasteTargetDetecting {
    private let workspace: NSWorkspace

    public init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    public func currentListOutputMode() -> ListOutputMode {
        let application = workspace.frontmostApplication
        return Self.listOutputMode(
            bundleIdentifier: application?.bundleIdentifier,
            windowTitle: application.flatMap(Self.frontmostWindowTitle(for:))
        )
    }

    nonisolated public static func listOutputMode(
        bundleIdentifier: String?,
        windowTitle: String? = nil
    ) -> ListOutputMode {
        if bundleIdentifier == "com.tinyspeck.slackmacgap" {
            return .semanticLists
        }

        let browserBundleIdentifiers: Set<String> = [
            "ai.perplexity.comet",
            "com.apple.Safari",
            "com.google.Chrome",
            "com.microsoft.edgemac",
            "company.thebrowser.Browser",
            "org.mozilla.firefox"
        ]
        if let bundleIdentifier,
           browserBundleIdentifiers.contains(bundleIdentifier),
           windowTitle?
            .split(separator: "|")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .localizedCaseInsensitiveCompare("Slack") == .orderedSame {
            return .semanticLists
        }

        return .literalMarkers
    }

    nonisolated private static func frontmostWindowTitle(
        for application: NSRunningApplication
    ) -> String? {
        let windowInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] ?? []

        return windowInfo.first { window in
            (window[kCGWindowOwnerPID as String] as? pid_t) == application.processIdentifier
                && (window[kCGWindowLayer as String] as? Int) == 0
        }?[kCGWindowName as String] as? String
    }
}
