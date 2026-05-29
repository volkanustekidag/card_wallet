import SwiftUI

/// Root list of loyalty cards on the watch. Empty state nudges the
/// user toward the phone, because card creation is intentionally
/// phone-only — typing a 13-character EAN on a watch is a worse UX
/// than just pulling out the phone.
struct ContentView: View {
    @EnvironmentObject private var store: LoyaltyCardStore

    var body: some View {
        NavigationStack {
            Group {
                if store.cards.isEmpty {
                    EmptyStateView()
                } else {
                    List(store.cards) { card in
                        NavigationLink(value: card.id) {
                            CardRow(card: card)
                        }
                    }
                    .listStyle(.carousel)
                }
            }
            .navigationTitle("Loyalty")
            .navigationDestination(for: String.self) { cardId in
                if let card = store.card(withId: cardId) {
                    CardDetailView(card: card)
                } else {
                    Text("Card unavailable")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct CardRow: View {
    let card: LoyaltyCard

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(card.displayName)
                .font(.headline)
                .lineLimit(2)
            if card.hasDistinctBrand {
                Text(card.brand)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.system(size: 28))
                .foregroundStyle(.tint)
            Text("Add cards on iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("They sync here automatically.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
