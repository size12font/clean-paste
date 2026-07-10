#!/usr/bin/env swift

import AppKit
import Foundation

struct Arguments {
    var outputDirectory: URL?
    var fullCapture = false
}

func parseArguments() -> Arguments {
    var arguments = Arguments()
    var index = 1
    let values = CommandLine.arguments

    while index < values.count {
        switch values[index] {
        case "--full":
            arguments.fullCapture = true
            index += 1
        case "--output":
            guard index + 1 < values.count else {
                fputs("missing value for --output\n", stderr)
                exit(2)
            }
            arguments.outputDirectory = URL(fileURLWithPath: values[index + 1])
            index += 2
        case "--help", "-h":
            print("usage: swift tools/dump-pasteboard.swift [--output <fixture-dir>] [--full]")
            exit(0)
        default:
            fputs("unknown argument: \(values[index])\n", stderr)
            exit(2)
        }
    }

    return arguments
}

func write(_ text: String, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try text.write(to: url, atomically: true, encoding: .utf8)
}

func redact(_ text: String) -> String {
    "[redacted \(text.count) chars]"
}

func jsonData(_ object: Any) throws -> Data {
    try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
}

let arguments = parseArguments()
let pasteboard = NSPasteboard.general
let types = pasteboard.types?.map(\.rawValue).sorted() ?? []
let plain = pasteboard.string(forType: .string)
let html = pasteboard.string(forType: .html)
let rtf = pasteboard.data(forType: .rtf)
let now = ISO8601DateFormatter().string(from: Date())

let metadata: [String: Any] = [
    "capturedAt": now,
    "captureMode": arguments.fullCapture ? "external-full" : "external-redacted",
    "sourceHarness": "external_app",
    "category": arguments.outputDirectory?.deletingLastPathComponent().lastPathComponent ?? "unclassified",
    "changeCount": pasteboard.changeCount,
    "fullCapture": arguments.fullCapture,
    "types": types,
    "hasPlainText": plain != nil,
    "hasHTML": html != nil,
    "hasRTF": rtf != nil,
    "plainTextLength": plain?.count ?? 0,
    "htmlLength": html?.count ?? 0,
    "rtfLength": rtf?.count ?? 0,
    "privacy": arguments.fullCapture
        ? "full textual payload saved by explicit --full"
        : "raw clipboard text redacted; rerun with --full only for non-sensitive samples"
]

if let outputDirectory = arguments.outputDirectory {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    try jsonData(metadata).write(to: outputDirectory.appendingPathComponent("observed-formats.json"))

    if let plain {
        let filename = arguments.fullCapture ? "raw/plain.txt" : "source.redacted.txt"
        try write(arguments.fullCapture ? plain : redact(plain), to: outputDirectory.appendingPathComponent(filename))
    }

    if let html {
        let filename = arguments.fullCapture ? "raw/source.html" : "html.redacted.txt"
        try write(arguments.fullCapture ? html : redact(html), to: outputDirectory.appendingPathComponent(filename))
    }

    let expectedURL = outputDirectory.appendingPathComponent("expected-preview.txt")
    if !FileManager.default.fileExists(atPath: expectedURL.path) {
        try write("Replace this with the CleanPaste preview text expected for this fixture.\n", to: expectedURL)
    }

    print("Wrote fixture metadata to \(outputDirectory.path)")
} else {
    FileHandle.standardOutput.write(try jsonData(metadata))
    print("")
}
