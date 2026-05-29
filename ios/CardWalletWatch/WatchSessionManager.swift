import Foundation
import WatchConnectivity

/// Watch-side WCSession host. Receives the phone's loyalty card
/// snapshot via `applicationContext` (last-write-wins, persists across
/// reboots) and pushes it into the in-memory `LoyaltyCardStore`.
///
/// We deliberately *don't* register for messageReceived / userInfo
/// transfers — applicationContext is enough because:
///   - we always send full snapshots, never deltas,
///   - we don't need delivery acknowledgements,
///   - and applicationContext is replayed automatically when the watch
///     wakes / the app is launched, so missed updates self-heal.
final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published private(set) var isReachable: Bool = false
    @Published private(set) var activationError: String?

    private var store: LoyaltyCardStore?

    func bindStore(_ store: LoyaltyCardStore) {
        self.store = store
    }

    func activate() {
        guard WCSession.isSupported() else {
            activationError = "WatchConnectivity unsupported"
            return
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()

        // Apply any context that arrived while the app was killed.
        // WCSession holds the most recent applicationContext across
        // launches; we just need to flush it on activation.
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            applyContext(context)
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if let error = error {
                self.activationError = error.localizedDescription
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String : Any]
    ) {
        applyContext(applicationContext)
    }

    private func applyContext(_ context: [String: Any]) {
        guard
            let json = context["loyalty_payload"] as? String,
            let data = json.data(using: .utf8),
            let payload = try? JSONDecoder().decode(LoyaltyCardPayload.self, from: data)
        else {
            return
        }
        Task { @MainActor in
            self.store?.apply(payload: payload)
        }
    }
}
