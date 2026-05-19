import WidgetKit
import SwiftUI

/// Shortcut widget that puts the user's most recently opened loyalty
/// card one tap away. Tapping deep-links into the app at
/// `cardwallet://loyalty?id=<card-id>`, which bypasses the PIN gate and
/// jumps straight to the full-screen barcode page.
///
/// Supported families:
///   - `.accessoryRectangular` / `.accessoryCircular` / `.accessoryInline`
///     (iOS 16+ Lock Screen). Text-only — lock-screen surfaces are too
///     small / too monochrome for a scannable barcode.
///   - `.systemSmall` / `.systemMedium` (Home Screen). Renders a small
///     scannable barcode preview for the formats CoreImage supports;
///     other formats fall back to the raw number.
struct LoyaltyWidget: Widget {
    let kind: String = "LoyaltyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoyaltyProvider()) { entry in
            if #available(iOS 17.0, *) {
                LoyaltyWidgetView(entry: entry)
                    .containerBackground(for: .widget) {
                        BackgroundGradient(
                            primaryHex: entry.primaryHex,
                            secondaryHex: entry.secondaryHex
                        )
                    }
            } else {
                LoyaltyWidgetView(entry: entry)
                    .background(
                        BackgroundGradient(
                            primaryHex: entry.primaryHex,
                            secondaryHex: entry.secondaryHex
                        )
                    )
            }
        }
        .configurationDisplayName("Loyalty Card")
        .description("Quickly show your most recent loyalty card barcode.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOS 16.0, *) {
            return [
                .systemSmall,
                .systemMedium,
                .accessoryRectangular,
                .accessoryCircular,
                .accessoryInline,
            ]
        } else {
            return [.systemSmall, .systemMedium]
        }
    }
}

// MARK: - Root view

private struct LoyaltyWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: LoyaltyEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                AccessoryRectangularView(entry: entry)
            case .accessoryCircular:
                AccessoryCircularView(entry: entry)
            case .accessoryInline:
                AccessoryInlineView(entry: entry)
            case .systemMedium:
                SystemMediumView(entry: entry)
            default:
                SystemSmallView(entry: entry)
            }
        }
        .widgetURL(deepLinkURL)
    }

    private var deepLinkURL: URL? {
        if entry.hasCard {
            return URL(string: "cardwallet://loyalty?id=\(entry.id)")
        }
        // Empty state — tap routes into the app where the user can add
        // a card. No id => handler falls back to default app behaviour.
        return URL(string: "cardwallet://loyalty")
    }
}

// MARK: - Home Screen families

private struct SystemSmallView: View {
    let entry: LoyaltyEntry

    var body: some View {
        if entry.hasCard {
            VStack(spacing: 6) {
                Text(entry.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                BarcodePreview(entry: entry, fillAvailable: true)
                Text(entry.barcode)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(10)
        } else {
            EmptyStateView(compact: true)
        }
    }
}

private struct SystemMediumView: View {
    let entry: LoyaltyEntry

    var body: some View {
        if entry.hasCard {
            VStack(spacing: 6) {
                HStack {
                    Text(entry.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 6)
                    if entry.hasDistinctBrand {
                        Text(entry.brand)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                BarcodePreview(entry: entry, fillAvailable: true)
                Text(entry.barcode)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(10)
        } else {
            EmptyStateView(compact: false)
        }
    }
}

// MARK: - Lock Screen families (iOS 16+)

@available(iOS 16.0, *)
private struct AccessoryRectangularView: View {
    let entry: LoyaltyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "barcode")
                Text(entry.hasCard ? entry.displayName : "Loyalty")
                    .font(.headline)
                    .lineLimit(1)
            }
            Text(entry.hasCard ? "Tap to show barcode" : "Add a loyalty card")
                .font(.caption2)
                .lineLimit(1)
                .opacity(0.8)
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
            Image(systemName: entry.hasCard ? "barcode.viewfinder" : "plus")
                .font(.system(size: 22, weight: .semibold))
        }
    }
}

@available(iOS 16.0, *)
private struct AccessoryInlineView: View {
    let entry: LoyaltyEntry

    var body: some View {
        if entry.hasCard {
            Label(entry.displayName, systemImage: "barcode")
        } else {
            Label("Add loyalty card", systemImage: "plus")
        }
    }
}

// MARK: - Shared components

private struct BarcodePreview: View {
    let entry: LoyaltyEntry
    /// When true, the barcode panel stretches to fill its container.
    /// This is the right mode for the home-screen widgets where the
    /// barcode IS the widget — the cashier should be able to scan
    /// straight from the home screen without launching the app.
    var fillAvailable: Bool = false
    var explicitHeight: CGFloat? = nil

    var body: some View {
        Group {
            if BarcodeRenderer.supportsInlineRendering(format: entry.format),
               let image = BarcodeRenderer.image(for: entry.barcode, format: entry.format) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
            } else {
                // Unsupported format (EAN/UPC) — CoreImage on iOS doesn't
                // ship generators for these. Show the raw number large +
                // a glyph so the user can read the code; tapping opens the
                // app where Flutter's barcode_widget can render every
                // format properly.
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "barcode")
                                .foregroundColor(.black.opacity(0.7))
                                .font(.system(size: 22))
                            Text("Tap to scan")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.black.opacity(0.55))
                        }
                    )
            }
        }
        .frame(
            maxWidth: fillAvailable ? .infinity : nil,
            maxHeight: explicitHeight ?? (fillAvailable ? .infinity : nil)
        )
    }
}

private struct EmptyStateView: View {
    let compact: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: compact ? 24 : 30, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            Text("Add a loyalty card")
                .font(.system(size: compact ? 11 : 13, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            if !compact {
                Text("Tap to open the app")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
    }
}

private struct BackgroundGradient: View {
    let primaryHex: String
    let secondaryHex: String

    var body: some View {
        LinearGradient(
            colors: [
                Color(hex: primaryHex) ?? Color(white: 0.15),
                Color(hex: secondaryHex) ?? Color(white: 0.05),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color helper

private extension Color {
    /// Parse a `#RRGGBB` string (the format the Flutter side writes via
    /// WidgetDataService._toHex). Returns nil for malformed input — the
    /// callsite falls back to a neutral grey.
    init?(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else {
            return nil
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
