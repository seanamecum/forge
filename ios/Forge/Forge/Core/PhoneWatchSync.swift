import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity

/// iPhone → Watch push of the directive snapshot. Fire-and-forget: unsupported
/// device, no paired watch, or inactive session are all silent no-ops.
final class PhoneWatchSync: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSync()
    private var pending: WidgetSnapshot?

    func push(_ snapshot: WidgetSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil { session.delegate = self }
        switch session.activationState {
        case .activated:
            send(snapshot, over: session)
        default:
            pending = snapshot
            session.activate()
        }
    }

    private func send(_ snapshot: WidgetSnapshot, over session: WCSession) {
        guard session.isPaired, session.isWatchAppInstalled,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? session.updateApplicationContext(["snapshot": data])
    }

    // WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        if state == .activated, let snapshot = pending {
            pending = nil
            send(snapshot, over: session)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
#endif
