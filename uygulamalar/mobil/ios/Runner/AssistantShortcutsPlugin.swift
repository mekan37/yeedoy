import Flutter
import UIKit

/// Registers NSUserActivity donations for Siri Shortcuts suggestions.
class AssistantShortcutsPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.yeedoy.app/assistant_shortcuts",
      binaryMessenger: registrar.messenger()
    )
    let instance = AssistantShortcutsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "donateActivity",
          let args = call.arguments as? [String: Any],
          let activityType = args["activityType"] as? String,
          let title = args["title"] as? String
    else {
      result(FlutterMethodNotImplemented)
      return
    }

    let activity = NSUserActivity(activityType: activityType)
    activity.title = title
    activity.isEligibleForSearch = true
    activity.isEligibleForPrediction = true
    if let userInfo = args["userInfo"] as? [String: String] {
      activity.userInfo = userInfo
    }
    // Persist the activity so the OS can index it.
    activity.becomeCurrent()
    result(nil)
  }
}
