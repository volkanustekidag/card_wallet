import Flutter
import UIKit
import UniformTypeIdentifiers
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

  /// Dart `SensitiveClipboard` copies card numbers / IBANs / barcodes
  /// through here so iOS itself expires them — a Dart timer can't fire
  /// while the app is suspended.
  private let clipboardChannelName = "app.cardwallet/sensitive_clipboard"
  private var clipboardChannel: FlutterMethodChannel?

  /// Dart `HiveBackupExclusion` keeps the Hive files out of iCloud /
  /// iTunes backups: their Keychain keys never leave the device, so a
  /// restored copy on a new phone could not be decrypted anyway.
  private let backupExclusionChannelName = "app.cardwallet/backup_exclusion"
  private var backupExclusionChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    activateWatchSession()
    observeSceneActivation()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerWatchSyncChannel(with: engineBridge.pluginRegistry)
    registerClipboardChannel(with: engineBridge.pluginRegistry)
    registerBackupExclusionChannel(with: engineBridge.pluginRegistry)
  }

  // MARK: - Backup exclusion

  private func registerBackupExclusionChannel(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "BackupExclusionChannel")?.messenger() else {
      return
    }
    let channel = FlutterMethodChannel(name: backupExclusionChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "invalid_args", message: "path is required", details: nil))
        return
      }
      do {
        // The directory flag covers files created later (new boxes, Hive
        // compaction rewrites); the per-file flag is belt and braces.
        let directory = URL(fileURLWithPath: path, isDirectory: true)
        try Self.excludeFromBackup(directory)
        let files = try FileManager.default.contentsOfDirectory(
          at: directory,
          includingPropertiesForKeys: nil
        )
        for file in files where ["hive", "lock"].contains(file.pathExtension) {
          try Self.excludeFromBackup(file)
        }
        result(true)
      } catch {
        result(FlutterError(
          code: "exclude_failed",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
    backupExclusionChannel = channel
  }

  private static func excludeFromBackup(_ url: URL) throws {
    var mutableURL = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try mutableURL.setResourceValues(values)
  }

  // MARK: - Sensitive clipboard

  private func registerClipboardChannel(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "SensitiveClipboardChannel")?.messenger() else {
      return
    }
    let channel = FlutterMethodChannel(name: clipboardChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "copy" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let text = args["text"] as? String else {
        result(FlutterError(code: "invalid_args", message: "text is required", details: nil))
        return
      }
      let seconds = (args["expiresInSeconds"] as? NSNumber)?.doubleValue ?? 60
      // localOnly keeps it off Universal Clipboard (other Apple devices);
      // expirationDate makes iOS drop it even if we're suspended.
      UIPasteboard.general.setItems(
        [[UTType.utf8PlainText.identifier: text]],
        options: [
          .localOnly: true,
          .expirationDate: Date().addingTimeInterval(seconds),
        ]
      )
      result(true)
    }
    clipboardChannel = channel
  }

  // MARK: - App-switcher privacy overlay

  /// The app runs on UIScene (FlutterSceneDelegate in Info.plist), so the
  /// UIApplicationDelegate resign/become-active callbacks are never called.
  /// Listen for the scene notifications instead; they fire for every scene
  /// regardless of which object is its delegate.
  private func observeSceneActivation() {
    let center = NotificationCenter.default
    center.addObserver(
      self,
      selector: #selector(sceneWillDeactivate(_:)),
      name: UIScene.willDeactivateNotification,
      object: nil
    )
    center.addObserver(
      self,
      selector: #selector(sceneDidActivate(_:)),
      name: UIScene.didActivateNotification,
      object: nil
    )
  }

  @objc private func sceneWillDeactivate(_ notification: Notification) {
    guard let scene = notification.object as? UIWindowScene else { return }
    presentPrivacyOverlay(in: scene)
  }

  @objc private func sceneDidActivate(_ notification: Notification) {
    dismissPrivacyOverlay()
  }

  private func presentPrivacyOverlay(in scene: UIWindowScene) {
    guard privacyOverlay == nil,
          let window = scene.keyWindow ?? scene.windows.first else {
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
