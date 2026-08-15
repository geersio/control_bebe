import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let lactationDarwinNotify = "com.controlbebe.lactation.timer.changed" as CFString

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerLactationDarwinObserver()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    LactationTimerChannel.register(with: engineBridge.applicationRegistrar.messenger())
  }

  private func registerLactationDarwinObserver() {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = Unmanaged.passUnretained(self).toOpaque()
    CFNotificationCenterAddObserver(
      center,
      observer,
      { _, observer, _, _, _ in
        guard let observer else { return }
        let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
        appDelegate.handleLactationDarwinNotification()
      },
      AppDelegate.lactationDarwinNotify,
      nil,
      .deliverImmediately
    )
  }

  private func handleLactationDarwinNotification() {
    LactationTimerNativeBridge.syncSharedStateToMainApp()
    let action = LactationTimerNativeBridge.consumePendingNativeAction() ?? "sync"
    if action == "stop" {
      LactationTimerNativeBridge.playSavedHaptic()
    }
    LactationTimerChannel.notify(action: action)
  }
}
