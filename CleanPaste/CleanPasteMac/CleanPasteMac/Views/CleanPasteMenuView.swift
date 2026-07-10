import CleanPasteMacCore
import SwiftUI

struct CleanPasteMenuView: View {
    let controller: CleanPasteController
    @ObservedObject var previewModel: PreviewModel
    @ObservedObject var launchAtLoginModel: LaunchAtLoginModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            actions
            preview
            preferences
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CleanPaste")
                .font(.title2.weight(.bold))
            Text("Automatic clipboard cleaning is on")
                .font(.headline)
                .foregroundStyle(.green)
            Text(previewModel.status.message)
                .font(.body)
                .foregroundStyle(statusStyle)
                .lineLimit(2)
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button {
                controller.cleanClipboardNow()
            } label: {
                Label("Clean clipboard now", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("c", modifiers: [.command])
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preview")
                .font(.headline)
            ScrollView {
                Text(previewModel.previewText.isEmpty ? "No cleaned text yet." : previewModel.previewText)
                    .font(.system(.title3, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .frame(minHeight: 150, maxHeight: 220)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var preferences: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLoginModel.isEnabled },
                set: { launchAtLoginModel.setEnabled($0) }
            ))

            if let lastError = launchAtLoginModel.lastError {
                Text(lastError)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            Divider()

            Button("Quit CleanPaste") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.plain)
        }
    }

    private var statusStyle: some ShapeStyle {
        switch previewModel.status {
        case .failed:
            AnyShapeStyle(.red)
        case .manualPasteRequired:
            AnyShapeStyle(.orange)
        default:
            AnyShapeStyle(.secondary)
        }
    }
}
