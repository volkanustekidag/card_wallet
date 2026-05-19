import WidgetKit
import SwiftUI

/// One render slice for the widget timeline. `id` empty => empty state
/// (the user has not opened any loyalty card yet, or the cached one was
/// deleted). The widget reads each field from the shared App Group
/// UserDefaults written by the Flutter side (see WidgetDataService.dart).
struct LoyaltyEntry: TimelineEntry {
    let date: Date
    let id: String
    let name: String
    let brand: String
    let barcode: String
    let format: String
    let primaryHex: String
    let secondaryHex: String

    var hasCard: Bool { !id.isEmpty && !barcode.isEmpty }
    var displayName: String { name.isEmpty ? brand : name }
    var hasDistinctBrand: Bool { !brand.isEmpty && brand != name }

    static let placeholder = LoyaltyEntry(
        date: Date(),
        id: "preview-id",
        name: "Starbucks Rewards",
        brand: "Starbucks",
        barcode: "1234567890",
        format: "CODE_128",
        primaryHex: "#1F2937",
        secondaryHex: "#111827"
    )

    static let empty = LoyaltyEntry(
        date: Date(),
        id: "",
        name: "",
        brand: "",
        barcode: "",
        format: "",
        primaryHex: "#1F2937",
        secondaryHex: "#111827"
    )
}
