# iOS Loyalty Widget — Xcode setup

All the Swift sources, entitlements, and Info.plist are already on disk
in `ios/LoyaltyWidget/`. The Flutter / Dart side is wired up. The
remaining work is **Xcode UI only** — adding the Widget Extension target
and linking the files to it. Budget ~5 minutes.

Bundle IDs / identifiers used below:
- App: `com.volkan.walletapp`
- Widget: `com.volkan.walletapp.LoyaltyWidget`
- App Group: `group.com.volkan.walletapp`
- URL scheme: `cardwallet`

---

## 1. Add the Widget Extension target

1. Open `ios/Runner.xcworkspace` in Xcode (the **workspace**, not the
   `.xcodeproj` — Pods need to be linked).
2. Select the `Runner` project in the navigator.
3. With the project selected, click the **+** button at the bottom of
   the target list (or **File → New → Target…**).
4. Choose **iOS → Widget Extension** and click **Next**.
5. Fill in the form:
   - Product Name: **`LoyaltyWidget`** (exact name — has to match
     `kind` in `LoyaltyWidget.swift` and the Dart `_iOSWidgetName`)
   - Team: same as the Runner target
   - Bundle Identifier: should auto-fill to
     `com.volkan.walletapp.LoyaltyWidget`
   - Language: **Swift**
   - **Uncheck** "Include Live Activity"
   - **Uncheck** "Include Configuration Intent" (we use static config)
6. Click **Finish**. If Xcode asks "Activate LoyaltyWidget scheme?",
   click **Cancel** (keep the Runner scheme active for builds).

Xcode just created a stub `LoyaltyWidget` folder with placeholder
files. The real implementation already lives in `ios/LoyaltyWidget/`
on disk — we need to swap them in.

## 2. Replace the stub files with the real sources

1. In the Xcode navigator, expand the new `LoyaltyWidget` group.
2. **Delete** the auto-generated stub files (right-click → Delete →
   **Move to Trash**):
   - `LoyaltyWidget.swift`
   - `LoyaltyWidgetBundle.swift` (if Xcode created one)
   - `Info.plist`
   - Any `Assets.xcassets` stub (delete unless you want widget icons)
3. Right-click the `LoyaltyWidget` group → **Add Files to "Runner"…**
4. Navigate to `ios/LoyaltyWidget/` on disk and select **all** of:
   - `LoyaltyWidget.swift`
   - `LoyaltyWidgetBundle.swift`
   - `Provider.swift`
   - `LoyaltyEntry.swift`
   - `BarcodeRenderer.swift`
   - `Info.plist`
   - `LoyaltyWidget.entitlements`
5. In the dialog:
   - "Destination": **leave unchecked** (Don't copy — files already
     live in `ios/LoyaltyWidget/`)
   - "Add to targets": **only check `LoyaltyWidget`**, uncheck `Runner`
6. Click **Add**.

## 3. Point the widget target at the right Info.plist + entitlements

1. Select the **`LoyaltyWidget`** target in the project editor.
2. **Build Settings** tab → search for **"Info.plist File"**.
   - Set it to `LoyaltyWidget/Info.plist`.
3. Search for **"Code Signing Entitlements"**.
   - Set it to `LoyaltyWidget/LoyaltyWidget.entitlements`.
4. Search for **"iOS Deployment Target"**.
   - Set it to **`16.0`** (Lock Screen widgets require iOS 16+).

## 4. Add the App Group capability to BOTH targets

The Runner app needs to *write* to the shared container; the Widget
needs to *read* from it. They have to declare the same group.

### 4a. Runner target

1. Select the **`Runner`** target.
2. **Signing & Capabilities** tab → click **+ Capability** → choose
   **App Groups**.
3. Under the new App Groups section, click **+** and add
   `group.com.volkan.walletapp`. Tick its checkbox.
4. **Build Settings** → search **"Code Signing Entitlements"**. It
   should now read `Runner/Runner.entitlements` (Xcode auto-created or
   referenced the file we pre-staged). If empty, set it explicitly.

### 4b. LoyaltyWidget target

1. Select the **`LoyaltyWidget`** target.
2. **Signing & Capabilities** → **+ Capability → App Groups**.
3. Add `group.com.volkan.walletapp` again, tick its checkbox.

Both targets must show the same group ID checked.

## 5. (Apple Developer portal) Register the App Group

Required on real devices and TestFlight; the simulator will work
without this step.

1. Sign in to <https://developer.apple.com/account/>.
2. **Certificates, IDs & Profiles → Identifiers → App Groups**.
3. Add `group.com.volkan.walletapp` if it isn't there.
4. Edit both app identifiers (`com.volkan.walletapp` and
   `com.volkan.walletapp.LoyaltyWidget`) and enable App Groups +
   tick the shared group.
5. Regenerate the provisioning profiles (Xcode does this automatically
   if you have "Automatically manage signing" turned on).

## 6. Build & verify

1. Pick the **Runner** scheme + an iOS 16+ simulator (or device).
2. ⌘R to run.
3. Open the app, navigate into a loyalty card's barcode page. (This
   primes the widget — `WidgetDataService` writes the snapshot.)
4. Background the app. Long-press the home screen → **+** → search
   "Loyalty Card" → add the widget.
5. Tap the widget → app should open straight to the barcode page,
   skipping the PIN.
6. For the Lock Screen widget: lock the device, long-press the lock
   screen, "Customize", tap a widget slot, select "Loyalty Card".

## 7. Known gotchas

- **Widget shows "Loyalty / Add a loyalty card"** even though you opened a
  card. → App Group entitlement is missing or misspelled on one of
  the two targets. Both must list `group.com.volkan.walletapp`.
- **Tap doesn't open the app to the barcode page.** → Check that
  `cardwallet` URL scheme is in `Runner/Info.plist` (it is — under
  `CFBundleURLTypes`). If you renamed the scheme, also update
  `widget_deep_link_handler.dart` and `LoyaltyWidget.swift`.
- **PIN screen still appears after widget tap.** → The bypass relies
  on `HomeWidget.initiallyLaunchedFromHomeWidget()` returning the URI
  before splash routes. If Xcode crashed and reattached during launch,
  the call sometimes returns nil — a clean cold launch from springboard
  always works.
- **EAN/UPC barcodes show as a placeholder glyph in the widget.**
  Intentional — CoreImage doesn't ship EAN generators on iOS. Tap into
  the app for the full-screen barcode (Flutter `barcode_widget` handles
  every format).

## 8. After it works — production checklist

- [ ] Bump iOS deployment target in Runner if it was below 16.0 (the
      widget extension's deployment target is independent, but the
      project minimum should match what you ship).
- [ ] Confirm the widget extension is included in TestFlight builds
      (Archive → Distribute → Validate → check the embedded products
      list).
- [ ] Add a screenshot of the widget to your App Store listing — Apple
      uses this in the widget gallery.
