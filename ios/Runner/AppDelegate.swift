import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Overlay shown while the app is inactive/backgrounded so card numbers
  // and IBANs never appear in the iOS app-switcher snapshot.
  private var privacyOverlay: UIView?

  /// MethodChannel name shared with the Dart side
  /// (`WatchSyncService`). Phone pushes the full loyalty card list
  /// here whenever the user adds / edits / deletes one; we forward via
  /// WCSession.updateApplicationContext.
  private let watchSyncChannelName = "app.cardwallet/watch_sync"
  private var watchSyncChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    activateWatchSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerWatchSyncChannel(with: engineBridge.pluginRegistry)
  }

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    presentPrivacyOverlay()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    dismissPrivacyOverlay()
  }

  private func presentPrivacyOverlay() {
    guard privacyOverlay == nil,
          let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            ?? UIApplication.shared.windows.first else {
      return
    }

    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = .systemBackground
    overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let blur = UIBlurEffect(style: .systemThickMaterial)
    let blurView = UIVisualEffectView(effect: blur)
    blurView.frame = overlay.bounds
    blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    overlay.addSubview(blurView)

    if let appIcon = UIImage(named: "AppIcon60x60") ?? UIImage(named: "LaunchImage") {
      let imageView = UIImageView(image: appIcon)
      imageView.contentMode = .scaleAspectFit
      imageView.translatesAutoresizingMaskIntoConstraints = false
      overlay.addSubview(imageView)
      NSLayoutConstraint.activate([
        imageView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
        imageView.widthAnchor.constraint(equalToConstant: 96),
        imageView.heightAnchor.constraint(equalToConstant: 96),
      ])
    }

    window.addSubview(overlay)
    privacyOverlay = overlay
  }

  private func dismissPrivacyOverlay() {
    privacyOverlay?.removeFromSuperview()
    privacyOverlay = nil
  }

  // MARK: - Apple Watch sync

  private func activateWatchSession() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    session.delegate = self
    session.activate()
  }

  /// MethodChannel that the Dart `WatchSyncService` posts loyalty card
  /// snapshots to. We register against the plugin registry rather than
  /// the FlutterViewController's binaryMessenger so the channel exists
  /// whether or not the implicit Flutter engine has attached a view
  /// yet — the Dart side may call this at app start before any UI is
  /// on screen.
  private func registerWatchSyncChannel(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "WatchSyncChannel")?.messenger() else {
      return
    }
    let channel = FlutterMethodChannel(
      name: watchSyncChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleWatchSyncCall(call, result: result)
    }
    watchSyncChannel = channel
  }

  private func handleWatchSyncCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "pushAllCards":
      guard let json = call.arguments as? String, !json.isEmpty else {
        result(FlutterError(
          code: "invalid_args",
          message: "Expected a JSON string payload",
          details: nil
        ))
        return
      }
      pushLoyaltyPayloadToWatch(jsonString: json, result: result)
    case "isPaired":
      // Used by the Dart side to surface a "watch app available" hint
      // in settings without having to know WC details.
      let paired = WCSession.isSupported() && WCSession.default.isPaired
      let installed = WCSession.isSupported() && WCSession.default.isWatchAppInstalled
      result([
        "paired": paired,
        "installed": installed,
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pushLoyaltyPayloadToWatch(
    jsonString: String,
    result: @escaping FlutterResult
  ) {
    guard WCSession.isSupported() else {
      result(false)
      return
    }
    let session = WCSession.default
    guard session.isPaired, session.isWatchAppInstalled else {
      // Not an error — the user just doesn't have the watch app yet.
      // The Dart side treats `false` as "not delivered, don't retry".
      result(false)
      return
    }
    do {
      // applicationContext replaces any previous payload (last-write-
      // wins) and is replayed when the watch wakes, so a missed delivery
      // self-heals on the next snapshot.
      try session.updateApplicationContext([
        "loyalty_payload": jsonString,
      ])
      result(true)
    } catch {
      result(FlutterError(
        code: "wc_failed",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }
}

// MARK: - WCSessionDelegate

extension AppDelegate: WCSessionDelegate {
  func session(
    _ session: WCSession,
    activationDidCompleteWith activationState: WCSessionActivationState,
    error: Error?
  ) {
    // Intentionally no-op — we only need an activated session so that
    // updateApplicationContext calls succeed. The Dart side polls
    // isPaired/isWatchAppInstalled via the MethodChannel.
  }

  func sessionDidBecomeInactive(_ session: WCSession) {
    // No-op. WC inactivates briefly when the user pairs / unpairs.
  }

  func sessionDidDeactivate(_ session: WCSession) {
    // Re-activate immediately so the next push can land. Required by
    // Apple's WCSession lifecycle — without this call after a
    // deactivation the session stays dead until app relaunch.
    WCSession.default.activate()
  }
}
