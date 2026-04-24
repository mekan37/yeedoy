import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Register the Siri Shortcuts donation plugin.
    if let registrar = registrar(forPlugin: "AssistantShortcutsPlugin") {
      AssistantShortcutsPlugin.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Siri Shortcuts / NSUserActivity

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Map NSUserActivity type to a yeedoy:// deep link and open it.
    let deepLink: String
    switch userActivity.activityType {
    case "com.yeedoy.app.findNearbyCheap":
      deepLink = "yeedoy://discover?sort=price_asc"
    case "com.yeedoy.app.openDiscover":
      deepLink = "yeedoy://discover"
    default:
      // Delegate URL-based activities (universal links) to super.
      return super.application(
        application,
        continue: userActivity,
        restorationHandler: restorationHandler
      )
    }

    if let url = URL(string: deepLink) {
      // Post via FlutterAppDelegate's URL handling so go_router picks it up.
      return super.application(application, open: url, options: [:])
    }
    return false
  }
}
