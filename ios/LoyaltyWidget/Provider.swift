import WidgetKit
import SwiftUI

/// Reads the hourly "Up Next" timeline the app writes to the App Group and
/// hands WidgetKit one entry per hour for the next day, so the widget
/// follows the user's routine without the app running. Falls back to the
/// legacy single-card keys written by older app versions.
struct LoyaltyProvider: TimelineProvider {
    static let appGroupId = "group.com.volkan.walletapp"

    func placeholder(in context: Context) -> LoyaltyEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (LoyaltyEntry) -> Void) {
        let entries = loadEntries()
        completion(context.isPreview && entries.isEmpty ? .placeholder : (current(of: entries) ?? .empty))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LoyaltyEntry>) -> Void) {
        let entries = loadEntries()
        if entries.isEmpty {
            completion(Timeline(entries: [.empty], policy: .never))
            return
        }
        // Start with the slot that covers "now".
        let now = Date()
        let upcoming = entries.filter { $0.date > now }
        let first = current(of: entries).map { LoyaltyEntry(date: now, cards: $0.cards, upNextLabel: $0.upNextLabel) }
        let all = (first.map { [$0] } ?? []) + upcoming
        completion(Timeline(entries: all.isEmpty ? [.empty] : all, policy: .atEnd))
    }

    private func current(of entries: [LoyaltyEntry]) -> LoyaltyEntry? {
        let now = Date()
        return entries.last(where: { $0.date <= now }) ?? entries.first
    }

    private func loadEntries() -> [LoyaltyEntry] {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId) else { return [] }
        var cardsById: [String: WidgetCard] = [:]
        if let raw = defaults.string(forKey: "cw_cards"),
           let data = raw.data(using: .utf8),
           let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for c in list {
                guard let id = c["id"] as? String else { continue }
                cardsById[id] = WidgetCard(
                    id: id,
                    name: c["name"] as? String ?? "",
                    barcode: c["barcode"] as? String ?? "",
                    format: c["format"] as? String ?? "",
                    bgHex: c["bg"] as? String ?? "#1F2937",
                    bg2Hex: c["bg2"] as? String ?? "#111827",
                    fgHex: c["fg"] as? String ?? "#FFFFFF",
                    imagePath: c["img"] as? String
                )
            }
        }
        if let raw = defaults.string(forKey: "cw_timeline"),
           let data = raw.data(using: .utf8),
           let slots = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           !cardsById.isEmpty {
            let entries: [LoyaltyEntry] = slots.compactMap { slot in
                guard let t = slot["t"] as? Double ?? (slot["t"] as? Int).map(Double.init),
                      let ids = slot["ids"] as? [String] else { return nil }
                let cards = ids.compactMap { cardsById[$0] }
                let label = defaults.string(forKey: "cw_label_upnext")
                return cards.isEmpty ? nil : LoyaltyEntry(
                    date: Date(timeIntervalSince1970: t), cards: cards,
                    upNextLabel: (label?.isEmpty ?? true) ? nil : label)
            }
            if !entries.isEmpty { return entries }
        }
        // Legacy single card.
        let id = defaults.string(forKey: "last_loyalty_id") ?? ""
        let barcode = defaults.string(forKey: "last_loyalty_barcode") ?? ""
        guard !id.isEmpty, !barcode.isEmpty else { return [] }
        let name = defaults.string(forKey: "last_loyalty_name") ?? ""
        let brand = defaults.string(forKey: "last_loyalty_brand") ?? ""
        let card = WidgetCard(
            id: id,
            name: name.isEmpty ? brand : name,
            barcode: barcode,
            format: defaults.string(forKey: "last_loyalty_format") ?? "",
            bgHex: defaults.string(forKey: "last_loyalty_color1") ?? "#1F2937",
            bg2Hex: defaults.string(forKey: "last_loyalty_color2") ?? "#111827",
            fgHex: "#FFFFFF",
            imagePath: nil
        )
        return [LoyaltyEntry(date: Date(), cards: [card])]
    }
}
