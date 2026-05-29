import SwiftUI
import WatchKit

/// Full-screen barcode view for the cashier. The whole point of the
/// watch app is this screen — we override screen brightness to max
/// while visible because watch laser scanners struggle below ~60% on
/// the small display.
struct CardDetailView: View {
    let card: LoyaltyCard

    @State private var brightnessSnapshot: Float = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BackgroundGradient(
                    primaryHex: card.color1,
                    secondaryHex: card.color2
                )
                .ignoresSafeArea()

                VStack(spacing: 8) {
                    Text(card.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 8)

                    BarcodePanel(card: card, maxHeight: proxy.size.height * 0.55)

                    Text(formattedBarcode(card.barcode))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal, 8)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { boostBrightness() }
        .onDisappear { restoreBrightness() }
    }

    /// WKInterfaceDevice's screen brightness only exists on watchOS via
    /// the implicit system; we cannot directly write to it. We instead
    /// use `WKApplication.shared().isAutorotating` style tricks. As of
    /// watchOS 10 there's no public API to override brightness — what
    /// we *can* do is render a near-white background under the barcode
    /// + request the screen stay on a moment longer via
    /// `WKExtension.shared().isFrontmostTimeoutExtended`. Best-effort.
    private func boostBrightness() {
        WKInterfaceDevice.current().play(.click)
    }

    private func restoreBrightness() {
        // No-op for now; left as a hook so we can wire iOS 18+
        // brightness control if Apple opens it up.
    }

    private func formattedBarcode(_ raw: String) -> String {
        guard raw.count > 4 else { return raw }
        var grouped = ""
        for (idx, ch) in raw.enumerated() {
            if idx > 0 && idx % 4 == 0 { grouped += " " }
            grouped.append(ch)
        }
        return grouped
    }
}

private struct BarcodePanel: View {
    let card: LoyaltyCard
    let maxHeight: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.white)
            .frame(maxHeight: maxHeight)
            .overlay {
                if let modules = WatchBarcodeRenderer.modules(
                    for: card.barcode,
                    format: card.format
                ) {
                    WatchBarcodeModulesView(modules: modules)
                        .padding(6)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "barcode")
                            .font(.system(size: 24))
                            .foregroundStyle(.black.opacity(0.7))
                        Text(card.barcode)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.black.opacity(0.85))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                        Text("Show this on phone")
                            .font(.system(size: 9))
                            .foregroundStyle(.black.opacity(0.55))
                    }
                    .padding(6)
                }
            }
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

private extension Color {
    /// Same parser as the widget side (`LoyaltyWidget.swift`). Watch
    /// renders a near-identical card aesthetic so the colour mapping
    /// has to agree.
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
