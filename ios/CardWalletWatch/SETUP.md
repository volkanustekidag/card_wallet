# Apple Watch companion — Xcode setup

All Swift sources, Info.plist, and asset catalog are staged at
`ios/CardWalletWatch/`. The Flutter / Dart side and the iOS
`AppDelegate.swift` are already wired. The remaining work is Xcode UI
(adding the watchOS app target + linking the prepared files).

Budget: ~10 minutes in Xcode + ~2 minutes in the Developer portal.
Plus a paired Apple Watch for real testing — the simulator won't show
you brightness behaviour or cashier-scan distance.

---

## Default decisions I made (override at will)

These were taken without your explicit sign-off — review and tell me if
you want any changed:

| Decision | What I picked | Why |
|---|---|---|
| **Sync scope** | All loyalty cards | WCSession.updateApplicationContext supports ~65KB; loyalty cards are tiny (~150 B each), so ~400+ fit easily. Simpler than "last N" with no real cost. |
| **Premium gate on watch** | None | Widget has no gate either. Gating loyalty barcode display feels punitive when the user already paid for cards on phone. |
| **PIN / biometric on watch** | None | Loyalty barcodes are designed to be shown publicly. Adding a passcode on the wrist is friction with no security gain. |
| **Complication (watch face shortcut)** | Not in v1 | Yet another target. Easy to add later as a second Widget Extension that shares the same store. |
| **Editing on watch** | Not supported | Adding a 13-digit EAN by Digital Crown is worse UX than the phone. Watch is read-only; the phone is the source of truth. |
| **Localization** | English only v1 | Watch SwiftUI strings are hard-coded for now. Adding the 9-language `.lproj` set is a separate pass. |
| **Brightness override** | Best-effort | watchOS 10 has no public brightness API. I render a white barcode panel; cashier scanners cope. iOS 18+ may open this up. |

---

## 1. Add the watchOS app target

1. Open `ios/Runner.xcworkspace` (the **workspace**, not the
   `.xcodeproj`).
2. **File → New → Target…**
3. Choose **watchOS → App** and click **Next**.
4. Fill in:
   - Product Name: **`CardWalletWatch`**
   - Team: same as Runner
   - Bundle Identifier: should auto-fill to
     `com.volkan.walletapp.CardWalletWatch`
     - Override it to **`com.volkan.walletapp.watchkitapp`** so it
       matches the `WKCompanionAppBundleIdentifier` convention.
       (Xcode used to enforce this naming; modern Xcode is permissive,
       but matching keeps you out of edge cases.)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Project: Runner
   - Embed in Application: **Runner**
   - **Uncheck** "Include Notification Scene" (we'll add later if we
     need push notifications)
   - **Uncheck** "Include Tests" (we have no test infra to wire it
     into yet)
5. Click **Finish**. If Xcode prompts "Activate CardWalletWatch
   scheme?", click **Activate** — you'll need this scheme when
   running on a watch.

Xcode creates a stub `CardWalletWatch Watch App` group with placeholder
files. Same pattern as the widget — we swap them.

## 2. Replace the stub files

1. In Xcode, expand the new `CardWalletWatch Watch App` group.
2. **Delete** every auto-generated file in the group (right-click →
   Delete → **Move to Trash**):
   - `CardWalletWatchApp.swift`
   - `ContentView.swift`
   - `Assets.xcassets`
   - `Preview Content/Preview Assets.xcassets`
3. Right-click the empty `CardWalletWatch Watch App` group →
   **Add Files to "Runner"…**
4. Navigate to `ios/CardWalletWatch/` and select all of:
   - `CardWalletWatchApp.swift`
   - `ContentView.swift`
   - `CardDetailView.swift`
   - `BarcodeRenderer.swift`
   - `LoyaltyCard.swift`
   - `LoyaltyCardStore.swift`
   - `WatchSessionManager.swift`
   - `Info.plist`
   - `Assets.xcassets` (the whole folder)
5. In the dialog:
   - "Destination": **leave unchecked** (files already live in
     `ios/CardWalletWatch/`)
   - "Add to targets": **only check `CardWalletWatch Watch App`**.
     Leave Runner unchecked — the watch app is a separate binary that
     gets embedded.
6. Click **Add**.

## 3. Wire the Info.plist + bundle ID

1. Select the **`CardWalletWatch Watch App`** target.
2. **Build Settings** → search "Info.plist File".
   - Set to `CardWalletWatch/Info.plist`.
3. Search "Product Bundle Identifier".
   - Set to `com.volkan.walletapp.watchkitapp` (matches the value
     baked into the staged Info.plist's `WKCompanionAppBundleIdentifier`).
4. Search "watchOS Deployment Target".
   - Set to **`9.0`** (covers Series 4+).

The staged `Info.plist` includes the keys watchOS needs:
- `WKApplication = true`
- `WKCompanionAppBundleIdentifier = com.volkan.walletapp`
- `WKRunsIndependentlyOfCompanionApp = false` (watch app only works
  while paired with the iPhone — change to `true` later if you ship a
  standalone Series 10+ build)

## 4. No App Group needed (but read this)

The watch app doesn't share storage with the iPhone — it gets its
data over WatchConnectivity, not a shared file. So **no App Group
capability** is required on the watch target.

The iPhone Runner target *does* already have App Group
`group.com.volkan.walletapp` from the widget setup — that group is
not used by the watch. Don't add it to the watch target; it would
just confuse the next person reading the entitlements.

## 5. WatchConnectivity has no entitlement

WatchConnectivity works as long as the watch app is paired with its
companion iOS app. No capability needs to be enabled in Xcode —
just `import WatchConnectivity` (already done in
`WatchSessionManager.swift` and the updated `AppDelegate.swift`).

## 6. Build & verify

### On the simulator (limited)

1. Pick the **`CardWalletWatch Watch App`** scheme + a paired
   iPhone-and-Apple-Watch simulator pair (e.g. "iPhone 15 + Apple
   Watch Series 9 (45mm)").
2. ⌘R. Both simulators boot.
3. On the phone simulator, open the Card Wallet app, add a loyalty
   card (or open an existing one).
4. The watch simulator app should populate within ~1–2 seconds.

The simulator does NOT exercise:
- Real brightness / scan-distance behaviour
- WC battery cost when phone is locked
- The "watch wakes after 12 hours, applicationContext replays"
  recovery path

### On a real device pair

1. Plug iPhone in, select the device + the watch as the run
   destination.
2. Build & install the iOS app first (the watch app embeds and pushes
   automatically).
3. From the iPhone Watch app (the one Apple ships), make sure
   "Card Wallet" is installed on the watch. If not, scroll down to
   "AVAILABLE APPS" and tap Install.
4. Open the loyalty card detail page on the phone. The watch should
   light up with the same card within ~1 second.
5. Try the watch app at a real cashier — note any scan failures and
   tune `BarcodeRenderer.image(scale:)` if needed.

## 7. Provisioning / Apple Developer portal

1. Sign in to <https://developer.apple.com/account/>.
2. **Certificates, IDs & Profiles → Identifiers**.
3. Register `com.volkan.walletapp.watchkitapp` if it isn't there.
4. With auto-signing on, Xcode will mint the profile on first build.
   Manual signing: regenerate the provisioning profile and download.

## 8. Known limitations / future work

- **No brightness override.** watchOS 10's brightness API is private.
  The white barcode panel + max system brightness while the app is
  frontmost is the best public-API answer today.
- **No complication.** A separate `WidgetKit` extension can show a
  shortcut on the watch face. Adding it = ~2 hours of Swift +
  another SETUP step; we'd reuse `LoyaltyCardStore` directly.
- **No standalone mode (Series 10+).** Watch only works while paired
  with the iPhone. Flip `WKRunsIndependentlyOfCompanionApp` to
  `true` once we've decided how a standalone watch would even add
  cards.
- **Hard-coded English UI.** Add a watch `Localizable.strings` set
  mirroring `assets/docs/lang/*.json` keys. Out of scope for v1.
- **No "open on iPhone" handoff.** Tapping a card on watch could
  push a notification to the phone to open the same card in full
  screen. Useful when the watch barcode won't scan. Out of scope v1.

## 9. Testing checklist

Before you ship:

- [ ] Adding a card on phone → appears on watch within 2 s
- [ ] Editing a card name on phone → updates on watch within 2 s
- [ ] Deleting a card on phone → removed from watch within 2 s
- [ ] Watch cold launch (force quit) → renders cached cards
      immediately
- [ ] Phone in airplane mode → existing cards still render on watch,
      changes queue and deliver when phone reconnects
- [ ] Watch cold launch with no cached cards + no phone → empty
      state ("Add cards on iPhone") renders cleanly
- [ ] Real cashier scan at 3 distances (10cm, 30cm, 50cm) — note
      any failures, tune scale
- [ ] Battery: leave watch app foregrounded 5 min, check phone
      battery delta vs control
