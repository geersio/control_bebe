import AppIntents
import Foundation

@available(iOS 17.0, *)
struct PauseLactationIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pausar lactancia"
    static var description = IntentDescription("Pausa el cronómetro de lactancia.")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        await LactationTimerNativeBridge.pause()
        return .result(dialog: IntentDialog(""))
    }
}

@available(iOS 17.0, *)
struct ResumeLactationIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reanudar lactancia"
    static var description = IntentDescription("Reanuda el cronómetro de lactancia.")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        await LactationTimerNativeBridge.resume()
        return .result(dialog: IntentDialog(""))
    }
}

@available(iOS 17.0, *)
struct StopLactationIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Parar lactancia"
    static var description = IntentDescription("Detiene el cronómetro y guarda la toma.")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        await LactationTimerNativeBridge.stopWithCelebration()
        return .result(dialog: IntentDialog(""))
    }
}
