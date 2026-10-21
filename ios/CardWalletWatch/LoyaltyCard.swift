import Foundation

/// Watch-side loyalty card model. Mirrors what the phone sends through
/// WatchConnectivity (see `WatchSyncService.dart` and the iOS
/// `AppDelegate` MethodChannel). Keep the field names byte-for-byte
/// aligned with the JSON the Dart side emits — no key remapping on
/// either end.
struct LoyaltyCard: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let barcode: String
    let format: String
    let color1: String
    let color2: String
    /// Usage stats (phone 2.2+). Optional so older payloads and the on-watch
    /// cache still decode. The phone already sends cards in usage order, so
    /// the list needs no sorting here.
    let useCount: Int?
    let lastUsedAt: String?

    var displayName: String { name.isEmpty ? brand : name }

    var hasDistinctBrand: Bool {
        !brand.isEmpty && brand != name
    }
}

/// Top-level payload posted by the phone. `version` is a soft contract
/// number; bump it when the shape changes incompatibly so the watch can
/// refuse to apply an unknown schema instead of crashing on a missing
/// field.
struct LoyaltyCardPayload: Codable {
    let version: Int
    let cards: [LoyaltyCard]
}
