import Foundation
import Combine

/// Single source of truth for the watch UI. Holds the latest loyalty
/// card list received from the phone, persisted to UserDefaults so the
/// watch can render immediately on cold launch — without persistence
/// the user would stare at an empty list for several seconds while
/// WCSession reconnects and replays applicationContext.
@MainActor
final class LoyaltyCardStore: ObservableObject {
    @Published private(set) var cards: [LoyaltyCard] = []
    @Published private(set) var lastSyncedAt: Date?

    private let persistenceKey = "watch.loyalty.cards.v1"
    private let lastSyncedKey = "watch.loyalty.lastSyncedAt"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadFromDisk()
    }

    /// Replace the entire card list. This is the only mutation path —
    /// the phone always sends a full snapshot via
    /// `updateApplicationContext`, never deltas. Cheaper to write, no
    /// merge logic to get wrong, and matches WC's "last write wins"
    /// applicationContext semantics.
    func apply(payload: LoyaltyCardPayload) {
        guard payload.version <= currentSupportedVersion else {
            // Phone is shipping a newer schema than this watch build
            // understands. Keep the previously-cached cards visible
            // rather than wiping the UI; the user can update the
            // watch app later.
            return
        }
        cards = payload.cards
        lastSyncedAt = Date()
        persistToDisk()
    }

    func card(withId id: String) -> LoyaltyCard? {
        cards.first { $0.id == id }
    }

    // MARK: - Persistence

    private let currentSupportedVersion = 1

    private func loadFromDisk() {
        if let data = defaults.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode([LoyaltyCard].self, from: data) {
            cards = decoded
        }
        if let date = defaults.object(forKey: lastSyncedKey) as? Date {
            lastSyncedAt = date
        }
    }

    private func persistToDisk() {
        if let data = try? JSONEncoder().encode(cards) {
            defaults.set(data, forKey: persistenceKey)
        }
        if let date = lastSyncedAt {
            defaults.set(date, forKey: lastSyncedKey)
        }
    }
}
