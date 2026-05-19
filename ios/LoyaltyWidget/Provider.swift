import WidgetKit
import SwiftUI

/// Reads the latest "last-used loyalty card" snapshot from the shared
/// App Group container and feeds it to the widget timeline.
///
/// The Flutter side calls `WidgetCenter.shared.reloadAllTimelines()` via
/// the home_widget plugin every time the user opens a loyalty card or
/// when the cached card is deleted, so we never need to poll. Returning
/// a single entry + `.never` policy keeps the system from burning the
/// widget refresh budget for nothing.
struct LoyaltyProvider: TimelineProvider {
    static let appGroupId = "group.com.volkan.walletapp"

    func placeholder(in context: Context) -> LoyaltyEntry {
        return LoyaltyEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (LoyaltyEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LoyaltyEntry>) -> Void) {
        let entry = currentEntry()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func currentEntry() -> LoyaltyEntry {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId) else {
            return .empty
        }
        let id = defaults.string(forKey: "last_loyalty_id") ?? ""
        let name = defaults.string(forKey: "last_loyalty_name") ?? ""
        let brand = defaults.string(forKey: "last_loyalty_brand") ?? ""
        let barcode = defaults.string(forKey: "last_loyalty_barcode") ?? ""
        let format = defaults.string(forKey: "last_loyalty_format") ?? ""
        let color1 = defaults.string(forKey: "last_loyalty_color1") ?? "#1F2937"
        let color2 = defaults.string(forKey: "last_loyalty_color2") ?? "#111827"

        if id.isEmpty || barcode.isEmpty {
            return .empty
        }

        return LoyaltyEntry(
            date: Date(),
            id: id,
            name: name,
            brand: brand,
            barcode: barcode,
            format: format,
            primaryHex: color1,
            secondaryHex: color2
        )
    }
}
