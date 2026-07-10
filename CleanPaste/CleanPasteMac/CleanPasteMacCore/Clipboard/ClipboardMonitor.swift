import Foundation

@MainActor
public final class ClipboardMonitor {
    private let reader: PasteboardReading
    private let pollingInterval: TimeInterval
    private var timer: Timer?
    private var lastObservedChangeCount: Int?
    private var onChange: ((PasteboardSnapshot) -> Void)?

    public init(
        reader: PasteboardReading = PasteboardReader(),
        pollingInterval: TimeInterval = 0.2
    ) {
        self.reader = reader
        self.pollingInterval = pollingInterval
    }

    public func start(onChange: @escaping (PasteboardSnapshot) -> Void) {
        stop()
        self.onChange = onChange
        lastObservedChangeCount = reader.snapshot().changeCount

        let timer = Timer(timeInterval: pollingInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        onChange = nil
    }

    public func poll() {
        let snapshot = reader.snapshot()
        guard snapshot.changeCount != lastObservedChangeCount else { return }

        lastObservedChangeCount = snapshot.changeCount
        onChange?(snapshot)

        // Cleaning rewrites the pasteboard and increments its change count.
        // Acknowledge that write so it is not mistaken for another user copy.
        lastObservedChangeCount = reader.snapshot().changeCount
    }

    public func acknowledgeCurrentClipboard() {
        lastObservedChangeCount = reader.snapshot().changeCount
    }
}
