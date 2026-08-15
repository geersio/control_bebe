import ActivityKit
import AudioToolbox
import CryptoKit
import Foundation
import os.log
import UIKit

/// Sincroniza el cronómetro entre Flutter (`SharedPreferences`), App Group y la Live Activity.
@available(iOS 16.1, *)
enum LactationTimerNativeBridge {
    private static let log = Logger(subsystem: "com.controlbebe.controlBebe", category: "LactationTimer")

    static let appGroupId = "group.com.controlbebe.controlBebe.liveactivity"
    static let activityName = "lactation_timer"
    static let flutterTimerKey = "flutter.control_bebe.lactation_timer.v1"
    static let timerJsonKey = "timerJson"
    static let confirmPhaseKey = "confirmPhase"
    static let pendingNativeActionKey = "lactationPendingNativeAction"
    static let pendingFeedingKey = "lactationPendingFeedingAdd"
    static let flutterPendingFeedingKey = "flutter.control_bebe.lactation_pending_feeding.v1"
    static let savedPhase = "saved"
    static let savedAnimationNs: UInt64 = 1_200_000_000

    struct TimerState {
        var side: Int
        var startedAt: Date
        var totalPausedMs: Int
        var pausedAt: Date?

        var isPaused: Bool { pausedAt != nil }

        func elapsedMs(at now: Date = Date()) -> Int64 {
            var paused = Int64(totalPausedMs)
            if let p = pausedAt {
                paused += Int64(now.timeIntervalSince(p) * 1000)
            }
            let raw = Int64(now.timeIntervalSince(startedAt) * 1000) - paused
            return max(0, raw)
        }
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static var appGroupDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    @MainActor
    static func loadTimer() -> TimerState? {
        if let activity = findLactationActivity(),
           let fromGroup = loadTimerFromAppGroup(activity: activity) {
            return fromGroup
        }
        return loadTimerFromFlutterPrefs()
    }

    private static func loadTimerFromAppGroup(activity: Activity<LiveActivitiesAppAttributes>) -> TimerState? {
        guard let shared = appGroupDefaults else { return nil }
        if let raw = shared.string(forKey: "\(activity.attributes.id)_\(timerJsonKey)"),
           let parsed = parseTimerJson(raw) {
            return parsed
        }

        let startedMs = shared.double(forKey: activity.attributes.prefixedKey("startedAtMs"))
        guard startedMs > 0 else { return nil }

        let sideIsLeft = lactationBool(shared: shared, prefix: activity.attributes, key: "sideIsLeft")
        let isPaused = lactationBool(shared: shared, prefix: activity.attributes, key: "isPaused")
        let totalPausedMs = Int(shared.double(forKey: activity.attributes.prefixedKey("totalPausedMs")))

        var pausedAt: Date?
        let pausedAtMs = shared.double(forKey: activity.attributes.prefixedKey("pausedAtMs"))
        if isPaused, pausedAtMs > 0 {
            pausedAt = Date(timeIntervalSince1970: pausedAtMs / 1000.0)
        }

        return TimerState(
            side: sideIsLeft ? 0 : 1,
            startedAt: Date(timeIntervalSince1970: startedMs / 1000.0),
            totalPausedMs: totalPausedMs,
            pausedAt: pausedAt
        )
    }

    private static func loadTimerFromFlutterPrefs() -> TimerState? {
        guard let raw = UserDefaults.standard.string(forKey: flutterTimerKey),
              let parsed = parseTimerJson(raw) else { return nil }
        return parsed
    }

    private static func parseTimerJson(_ raw: String) -> TimerState? {
        guard let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let startedAt: Date?
        if let ms = (json["startedAtMs"] as? NSNumber)?.int64Value, ms > 0 {
            startedAt = Date(timeIntervalSince1970: Double(ms) / 1000.0)
        } else if let startedIso = json["startedAt"] as? String {
            startedAt = parseIsoDate(startedIso)
        } else {
            startedAt = nil
        }
        guard let startedAt else { return nil }

        let side = (json["side"] as? NSNumber)?.intValue ?? 0
        let totalPausedMs = (json["totalPausedMs"] as? NSNumber)?.intValue ?? 0
        var pausedAt: Date?
        if let ms = (json["pausedAtMs"] as? NSNumber)?.int64Value, ms > 0 {
            pausedAt = Date(timeIntervalSince1970: Double(ms) / 1000.0)
        } else if let pausedIso = json["pausedAt"] as? String {
            pausedAt = parseIsoDate(pausedIso)
        }
        return TimerState(
            side: side,
            startedAt: startedAt,
            totalPausedMs: totalPausedMs,
            pausedAt: pausedAt
        )
    }

    @MainActor
    static func saveTimer(_ timer: TimerState) {
        var json: [String: Any] = [
            "side": timer.side,
            "startedAtMs": Int64(timer.startedAt.timeIntervalSince1970 * 1000),
            "startedAt": isoFormatter.string(from: timer.startedAt),
            "totalPausedMs": timer.totalPausedMs,
        ]
        if let p = timer.pausedAt {
            json["pausedAtMs"] = Int64(p.timeIntervalSince1970 * 1000)
            json["pausedAt"] = isoFormatter.string(from: p)
        }
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let str = String(data: data, encoding: .utf8) else { return }

        UserDefaults.standard.set(str, forKey: flutterTimerKey)
        if let shared = appGroupDefaults {
            shared.set(str, forKey: flutterTimerKey)
            if let activity = findLactationActivity() {
                shared.set(str, forKey: "\(activity.attributes.id)_\(timerJsonKey)")
            }
        }
    }

    @MainActor
    static func clearTimer() {
        UserDefaults.standard.removeObject(forKey: flutterTimerKey)
        appGroupDefaults?.removeObject(forKey: flutterTimerKey)
        if let activity = findLactationActivity(), let shared = appGroupDefaults {
            shared.removeObject(forKey: "\(activity.attributes.id)_\(timerJsonKey)")
        }
    }

    /// Copia solo el cronómetro al Runner. El outbox lo gestiona Flutter (evita resurrectar tomas borradas).
    @MainActor
    static func syncSharedStateToMainApp() {
        guard let shared = appGroupDefaults else { return }
        if let timerRaw = shared.string(forKey: flutterTimerKey) {
            UserDefaults.standard.set(timerRaw, forKey: flutterTimerKey)
        } else {
            UserDefaults.standard.removeObject(forKey: flutterTimerKey)
        }
        if let pending = shared.string(forKey: pendingFeedingKey) {
            UserDefaults.standard.set(pending, forKey: flutterPendingFeedingKey)
            shared.removeObject(forKey: pendingFeedingKey)
        }
        UserDefaults.standard.synchronize()
    }

    @MainActor
    static func pause() async {
        guard var timer = loadTimer(), !timer.isPaused else {
            log.warning("pause: no timer or already paused")
            return
        }
        timer.pausedAt = Date()
        saveTimer(timer)
        await refreshLiveActivity(timer: timer, confirmPhase: nil)
        notifyExternalChange(action: "pause")
        log.info("pause: ok")
    }

    @MainActor
    static func resume() async {
        guard var timer = loadTimer(), let pausedAt = timer.pausedAt else {
            log.warning("resume: no paused timer")
            return
        }
        let extra = Int(Date().timeIntervalSince(pausedAt) * 1000)
        timer.totalPausedMs += extra
        timer.pausedAt = nil
        saveTimer(timer)
        await refreshLiveActivity(timer: timer, confirmPhase: nil)
        notifyExternalChange(action: "resume")
        log.info("resume: ok")
    }

    @MainActor
    static func stopWithCelebration() async {
        guard let timer = loadTimer() else {
            log.warning("stop: no timer")
            return
        }
        let durationSec = max(1, Int(timer.elapsedMs() / 1000))
        let feedingType = timer.side == 0 ? 0 : 1
        let recordId = Int64(Date().timeIntervalSince1970 * 1_000_000)
        queuePendingFeedingAdd(
            id: recordId,
            type: feedingType,
            startedAt: timer.startedAt,
            durationSeconds: durationSec
        )
        clearTimer()
        playSavedHapticFromExtension()
        await refreshLiveActivity(timer: timer, confirmPhase: savedPhase)
        notifyExternalChange(action: "stop")
        try? await Task.sleep(nanoseconds: savedAnimationNs)
        await endLiveActivity()
        log.info("stop: saved \(durationSec)s")
    }

    /// En el proceso Runner (app principal); la extensión no tiene Taptic Engine fiable.
    static func playSavedHaptic() {
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        }
    }

    /// Fallback al pulsar Parar con la app cerrada o en segundo plano.
    private static func playSavedHapticFromExtension() {
        AudioServicesPlaySystemSound(1519)
    }

    private static func queuePendingFeedingAdd(
        id: Int64,
        type: Int,
        startedAt: Date,
        durationSeconds: Int
    ) {
        let payload: [String: Any] = [
            "id": id,
            "type": type,
            "dateTimeMs": Int64(startedAt.timeIntervalSince1970 * 1000),
            "durationSeconds": durationSeconds,
        ]
        let entry: [String: Any] = [
            "kind": "feeding_add",
            "payload": payload,
            "attempts": 0,
            "nextAfterMs": 0,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: entry),
              let str = String(data: data, encoding: .utf8) else { return }
        appGroupDefaults?.set(str, forKey: pendingFeedingKey)
    }

    /// App Group: acción pendiente para el Runner tras Darwin notify (extensión → app).
    static func notifyExternalChange(action: String) {
        appGroupDefaults?.set(action, forKey: pendingNativeActionKey)
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.controlbebe.lactation.timer.changed" as CFString),
            nil,
            nil,
            true
        )
    }

    static func consumePendingNativeAction() -> String? {
        guard let shared = appGroupDefaults else { return nil }
        let action = shared.string(forKey: pendingNativeActionKey)
        shared.removeObject(forKey: pendingNativeActionKey)
        return action
    }

    @MainActor
    private static func refreshLiveActivity(timer: TimerState?, confirmPhase: String?) async {
        guard let shared = appGroupDefaults else { return }
        guard let activity = findLactationActivity() else {
            log.warning("refresh: no active activity")
            return
        }

        let prefix = activity.attributes.id
        let tick = Int64(Date().timeIntervalSince1970 * 1000)

        if let timer {
            let elapsedMs = timer.elapsedMs()
            shared.set(timer.startedAt.timeIntervalSince1970 * 1000, forKey: "\(prefix)_startedAtMs")
            shared.set(timer.isPaused, forKey: "\(prefix)_isPaused")
            shared.set(timer.totalPausedMs, forKey: "\(prefix)_totalPausedMs")
            shared.set(Double(elapsedMs), forKey: "\(prefix)_frozenElapsedMs")
            shared.set(timer.side == 0, forKey: "\(prefix)_sideIsLeft")
            if let pausedAt = timer.pausedAt {
                shared.set(pausedAt.timeIntervalSince1970 * 1000, forKey: "\(prefix)_pausedAtMs")
            } else {
                shared.removeObject(forKey: "\(prefix)_pausedAtMs")
            }
            if let json = timerJsonString(timer) {
                shared.set(json, forKey: "\(prefix)_\(timerJsonKey)")
            }
        }
        if let confirmPhase {
            shared.set(confirmPhase, forKey: "\(prefix)_\(confirmPhaseKey)")
        } else {
            shared.removeObject(forKey: "\(prefix)_\(confirmPhaseKey)")
        }
        shared.set(tick, forKey: "\(prefix)_iosPresentationTick")

        let state = LiveActivitiesAppAttributes.LiveDeliveryData(
            appGroupId: appGroupId,
            contentRevision: tick
        )

        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: state, staleDate: nil)
            await activity.update(content)
        } else {
            await activity.update(using: state)
        }
    }

    private static func timerJsonString(_ timer: TimerState) -> String? {
        var json: [String: Any] = [
            "side": timer.side,
            "startedAtMs": Int64(timer.startedAt.timeIntervalSince1970 * 1000),
            "startedAt": isoFormatter.string(from: timer.startedAt),
            "totalPausedMs": timer.totalPausedMs,
        ]
        if let p = timer.pausedAt {
            json["pausedAtMs"] = Int64(p.timeIntervalSince1970 * 1000)
            json["pausedAt"] = isoFormatter.string(from: p)
        }
        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @MainActor
    private static func endLiveActivity() async {
        guard let activity = findLactationActivity() else { return }
        if let shared = appGroupDefaults {
            shared.removeObject(forKey: "\(activity.attributes.id)_\(confirmPhaseKey)")
        }
        if #available(iOS 16.2, *) {
            await activity.end(ActivityContent(state: activity.content.state, staleDate: nil), dismissalPolicy: .immediate)
        } else {
            await activity.end(dismissalPolicy: .immediate)
        }
    }

    @MainActor
    private static func findLactationActivity() -> Activity<LiveActivitiesAppAttributes>? {
        let targetId = uuid5(name: activityName)
        let activities = Activity<LiveActivitiesAppAttributes>.activities
        if let match = activities.first(where: {
            $0.attributes.id == targetId && $0.activityState == .active
        }) {
            return match
        }
        return activities.first { $0.activityState == .active }
    }

    private static func lactationBool(
        shared: UserDefaults,
        prefix: LiveActivitiesAppAttributes,
        key: String
    ) -> Bool {
        let k = prefix.prefixedKey(key)
        if let o = shared.object(forKey: k) {
            if let b = o as? Bool { return b }
            if let n = o as? NSNumber { return n.boolValue }
        }
        return false
    }

    private static func parseIsoDate(_ value: String) -> Date? {
        if let d = isoFormatter.date(from: value) { return d }
        let fallback = ISO8601DateFormatter()
        return fallback.date(from: value)
    }

    private static func uuid5(
        namespace: UUID = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!,
        name: String
    ) -> UUID {
        var namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Data($0) }
        namespaceBytes.append(Data(name.utf8))
        let hash = Insecure.SHA1.hash(data: namespaceBytes)
        var bytes = [UInt8](hash.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        let uuid = uuid_t(
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: uuid)
    }
}
