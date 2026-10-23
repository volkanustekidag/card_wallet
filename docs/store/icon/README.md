# App icon

Option A "Deste" (tangerine, card stack). Masters come from
`.context/design/v2/icon_render.html` (SVG, rendered at 1024 px).

| File | Where it goes |
|---|---|
| `app_store_1024.png` | App Store Connect (also the iOS / watchOS AppIcon source) |
| `play_store_512.png` | Play Console, store listing icon |
| `adaptive_foreground.png`, `adaptive_background.png` | Android adaptive icon sources (`flutter_icons` in pubspec) |
| `wallet_pass/icon*.png` | Wallet pass server: the directory behind `APPLE_ICON_PATH` |
| `wallet_pass/logo.png` | Wallet pass server: `APPLE_LOGO_PATH` |
| `wallet_pass/google-logo.png` | Wallet pass server: `GOOGLE_LOGO_PATH`, and the file at `GOOGLE_WALLET_LOGO_URL` |

The app itself (iOS AppIcon set, watch icon, Android mipmaps, monochrome
themed icon, notification glyph, splash logo) is already updated in the repo.
