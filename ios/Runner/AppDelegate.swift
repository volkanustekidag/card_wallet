import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Overlay shown while the app is inactive/backgrounded so card numbers
  // and IBANs never appear in the iOS app-switcher snapshot.
  private var privacyOverlay: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
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
}
