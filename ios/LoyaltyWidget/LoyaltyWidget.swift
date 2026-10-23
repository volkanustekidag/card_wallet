import WidgetKit
import SwiftUI

/// "Up Next" loyalty widget. Shows the card the user most likely needs at
/// this hour (learned on-device from their own use, published by the app
/// as an hourly timeline) with a scannable barcode; the medium size adds
/// the next three cards, each one tap away. Tapping deep-links to
/// `cardwallet://loyalty?id=…`, which opens the barcode page even while
/// the app is PIN-locked (read-only).
struct LoyaltyWidget: Widget {
    let kind: String = "LoyaltyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoyaltyProvider()) { entry in
            if #available(iOS 17.0, *) {
                LoyaltyWidgetView(entry: entry)
                    .containerBackground(for: .widget) { WidgetBackground(card: entry.upNext) }
            } else {
                LoyaltyWidgetView(entry: entry)
                    .background(WidgetBackground(card: entry.upNext))
            }
        }
        .configurationDisplayName(Text("Card Wallet"))
        .description(Text("The card you need now, ready to scan."))
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [.systemSmall, .systemMedium, .accessoryRectangular,
                    .accessoryCircular, .accessoryInline]
        }
        return [.systemSmall, .systemMedium]
    }
}

// MARK: - Root

private struct LoyaltyWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: LoyaltyEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular: AccessoryRectangularView(entry: entry)
            case .accessoryCircular: AccessoryCircularView(entry: entry)
            case .accessoryInline: AccessoryInlineView(entry: entry)
            case .systemMedium: MediumView(entry: entry)
            default: SmallView(entry: entry)
            }
        }
        .widgetURL(entry.upNext?.deepLink ?? URL(string: "cardwallet://loyalty?homeWidget=1"))
    }
}

// MARK: - Home screen

private struct SmallView: View {
    let entry: LoyaltyEntry

    var body: some View {
        if let card = entry.upNext {
            UpNextBlock(card: card, label: entry.upNextLabel)
                .padding(12)
        } else {
            EmptyStateView()
        }
    }
}

private struct MediumView: View {
    let entry: LoyaltyEntry

    var body: some View {
        if let card = entry.upNext {
            HStack(spacing: 10) {
                UpNextBlock(card: card, label: entry.upNextLabel)
                    .frame(maxWidth: .infinity)
                if !entry.others.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(entry.others.prefix(3)) { other in
                            Link(destination: other.deepLink ?? URL(string: "cardwallet://loyalty?homeWidget=1")!) {
                                CardRow(card: other, fg: Color(hex: card.fgHex) ?? .white)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(width: 118)
                }
            }
            .padding(12)
        } else {
            EmptyStateView()
        }
    }
}

/// "UP NEXT" + name + the barcode on a white panel.
private struct UpNextBlock: View {
    let card: WidgetCard
    var label: String? = nil

    var body: some View {
        let fg = Color(hex: card.fgHex) ?? .white
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                (label.map { Text(verbatim: $0) } ?? Text("Up Next"))
                    .font(.system(size: 9, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundColor(fg.opacity(0.7))
                Text(verbatim: card.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(fg)
                    .lineLimit(1)
            }
            BarcodePanel(card: card)
        }
    }
}

struct BarcodePanel: View {
    let card: WidgetCard

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .overlay(content.padding(6))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var content: some View {
        if let path = card.imagePath, let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else if BarcodeRenderer.supportsInlineRendering(format: card.format),
                  let image = BarcodeRenderer.image(for: card.barcode, format: card.format) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Text(verbatim: card.barcode)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.black)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
        }
    }
}

private struct CardRow: View {
    let card: WidgetCard
    let fg: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: card.bgHex) ?? .gray)
                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                .frame(width: 12, height: 12)
            Text(verbatim: card.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(fg)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 9).fill(Color.black.opacity(0.18)))
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.circle")
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            Text("Add a loyalty card")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
}

struct WidgetBackground: View {
    let card: WidgetCard?

    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: card?.bgHex ?? "#22252C") ?? Color(white: 0.15),
                Color(hex: card?.bg2Hex ?? "#0B0C0F") ?? Color(white: 0.05),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Lock screen (iOS 16+)

@available(iOS 16.0, *)
private struct AccessoryRectangularView: View {
    let entry: LoyaltyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: "barcode")
                (entry.upNextLabel.map { Text(verbatim: $0) } ?? Text("Up Next"))
                    .font(.caption2).textCase(.uppercase)
            }
            .opacity(0.8)
            if let card = entry.upNext {
                Text(verbatim: card.name).font(.headline).lineLimit(1)
            } else {
                Text("Add a loyalty card").font(.headline).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 16.0, *)
private struct AccessoryCircularView: View {
    let entry: LoyaltyEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: entry.upNext == nil ? "plus" : "barcode.viewfinder")
                .font(.system(size: 22, weight: .semibold))
        }
    }
}

@available(iOS 16.0, *)
private struct AccessoryInlineView: View {
    let entry: LoyaltyEntry

    var body: some View {
        if let card = entry.upNext {
            Label(card.name, systemImage: "barcode")
        } else {
            Label("Add loyalty card", systemImage: "plus")
        }
    }
}

// MARK: - Colour

extension Color {
    /// `#RRGGBB` as written by WidgetDataService._toHex.
    init?(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0
        )
    }
}
