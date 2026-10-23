import AppIntents
import SwiftUI
import WidgetKit

/// "Pinned card" widget (iOS 17+): always the card the user picked in the
/// widget's settings (touch and hold → Edit Widget), barcode ready to scan.
/// The list of cards comes from `cw_all_cards`, written by the app
/// (WidgetDataService.reconcile) with a pre-rendered barcode per card.
@available(iOS 17.0, *)
struct PinnedCardWidget: Widget {
    let kind: String = "PinnedCardWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCardIntent.self, provider: PinnedCardProvider()) { entry in
            PinnedCardView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground(card: entry.card) }
        }
        .configurationDisplayName(Text("Pinned card"))
        .description(Text("Always shows the card you choose, ready to scan."))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Configuration

@available(iOS 17.0, *)
struct CardEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Card"
    static var defaultQuery = CardQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 17.0, *)
struct CardQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [CardEntity] {
        WidgetCardStore.all()
            .filter { identifiers.contains($0.id) }
            .map { CardEntity(id: $0.id, name: $0.name) }
    }

    func entities(matching string: String) async throws -> [CardEntity] {
        WidgetCardStore.all()
            .filter { $0.name.localizedCaseInsensitiveContains(string) }
            .map { CardEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [CardEntity] {
        WidgetCardStore.all().map { CardEntity(id: $0.id, name: $0.name) }
    }
}

@available(iOS 17.0, *)
struct SelectCardIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose a card"
    static var description = IntentDescription("Always show this card's barcode.")

    @Parameter(title: "Card")
    var card: CardEntity?
}

// MARK: - Timeline

struct PinnedEntry: TimelineEntry {
    let date: Date
    let card: WidgetCard?
    /// A card was chosen but isn't in the wallet any more.
    let missing: Bool
}

@available(iOS 17.0, *)
struct PinnedCardProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PinnedEntry {
        PinnedEntry(date: Date(), card: LoyaltyEntry.placeholder.upNext, missing: false)
    }

    func snapshot(for configuration: SelectCardIntent, in context: Context) async -> PinnedEntry {
        entry(for: configuration, preview: context.isPreview)
    }

    func timeline(for configuration: SelectCardIntent, in context: Context) async -> Timeline<PinnedEntry> {
        // The app reloads this widget whenever cards change.
        Timeline(entries: [entry(for: configuration, preview: false)], policy: .never)
    }

    private func entry(for configuration: SelectCardIntent, preview: Bool) -> PinnedEntry {
        let all = WidgetCardStore.all()
        if let id = configuration.card?.id {
            let card = all.first(where: { $0.id == id })
            return PinnedEntry(date: Date(), card: card, missing: card == nil)
        }
        if preview {
            return PinnedEntry(date: Date(), card: all.first ?? LoyaltyEntry.placeholder.upNext, missing: false)
        }
        return PinnedEntry(date: Date(), card: nil, missing: false)
    }
}

/// Every card the app published, A to Z.
enum WidgetCardStore {
    static func all() -> [WidgetCard] {
        guard let defaults = UserDefaults(suiteName: LoyaltyProvider.appGroupId),
              let raw = defaults.string(forKey: "cw_all_cards"),
              let data = raw.data(using: .utf8),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }
        return list.compactMap { c in
            guard let id = c["id"] as? String else { return nil }
            return WidgetCard(
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
}

// MARK: - Views

private struct PinnedCardView: View {
    @Environment(\.widgetFamily) var family
    let entry: PinnedEntry

    var body: some View {
        Group {
            if let card = entry.card {
                switch family {
                case .accessoryRectangular:
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Image(systemName: "barcode")
                            Text("Tap to show barcode").font(.caption2)
                        }
                        .opacity(0.8)
                        Text(verbatim: card.name).font(.headline).lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                default:
                    let fg = Color(hex: card.fgHex) ?? .white
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: card.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(fg)
                            .lineLimit(1)
                        BarcodePanel(card: card)
                    }
                    .padding(12)
                }
            } else {
                ChooseCardView(missing: entry.missing, compact: family == .accessoryRectangular)
            }
        }
        .widgetURL(entry.card?.deepLink ?? URL(string: "cardwallet://loyalty?homeWidget=1"))
    }
}

private struct ChooseCardView: View {
    let missing: Bool
    let compact: Bool

    var body: some View {
        if compact {
            VStack(alignment: .leading, spacing: 1) {
                Image(systemName: "hand.tap")
                (missing ? Text("This card is no longer in your wallet") : Text("Touch and hold to choose a card"))
                    .font(.caption)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 6) {
                Image(systemName: missing ? "exclamationmark.circle" : "hand.tap")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                (missing ? Text("This card is no longer in your wallet") : Text("Touch and hold to choose a card"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
        }
    }
}
