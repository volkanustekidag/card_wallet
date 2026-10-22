import WidgetKit
import SwiftUI

/// A loyalty card as published by the app (WidgetDataService.reconcile):
/// colours follow the card's look in the app; `imagePath` is a PNG of the
/// barcode rendered by the app itself, so every format scans.
struct WidgetCard: Identifiable, Hashable {
    let id: String
    let name: String
    let barcode: String
    let format: String
    let bgHex: String
    let bg2Hex: String
    let fgHex: String
    let imagePath: String?

    var deepLink: URL? {
        // `homeWidget=1` is required by the home_widget plugin's URL filter.
        URL(string: "cardwallet://loyalty?homeWidget=1&id=\(id)")
    }
}

/// One timeline slot: the cards to show, best guess first ("Up Next").
struct LoyaltyEntry: TimelineEntry {
    let date: Date
    let cards: [WidgetCard]

    var upNext: WidgetCard? { cards.first }
    var others: [WidgetCard] { Array(cards.dropFirst()) }

    static let placeholder = LoyaltyEntry(date: Date(), cards: [
        WidgetCard(id: "preview", name: "Coffee Club", barcode: "6061234567890123",
                   format: "CODE_128", bgHex: "#1A8A62", bg2Hex: "#0D4F3B",
                   fgHex: "#FFFFFF", imagePath: nil),
        WidgetCard(id: "p2", name: "Grocer", barcode: "1", format: "CODE_128",
                   bgHex: "#D7332F", bg2Hex: "#8E1B1F", fgHex: "#FFFFFF", imagePath: nil),
        WidgetCard(id: "p3", name: "Books", barcode: "1", format: "CODE_128",
                   bgHex: "#3F8FD8", bg2Hex: "#136A8A", fgHex: "#FFFFFF", imagePath: nil),
    ])

    static let empty = LoyaltyEntry(date: Date(), cards: [])
}
