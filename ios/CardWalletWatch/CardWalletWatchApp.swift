import SwiftUI

/// Watch companion entry point. The whole app is intentionally
/// read-only — adding / editing / deleting cards always happens on the
/// phone, which then syncs the new state via WatchConnectivity. The
/// watch surface exists for one job: show a loyalty barcode at the
/// cashier without taking your phone out.
@main
struct CardWalletWatchApp: App {
    @StateObject private var store = LoyaltyCardStore()
    @StateObject private var session = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    session.bindStore(store)
                    session.activate()
                }
        }
    }
}
