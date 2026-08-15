import Flutter
import Foundation

/// Notifica a Flutter cuando la Live Activity cambia el cronómetro en nativo.
enum LactationTimerChannel {
    private static let channelName = "com.controlbebe/lactation_timer"

    static func register(with messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    }

    private static var channel: FlutterMethodChannel?

    static func notify(action: String) {
        DispatchQueue.main.async {
            channel?.invokeMethod("timerChanged", arguments: ["action": action])
        }
    }
}
