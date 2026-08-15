import AppIntents
import Foundation

/// Registra los App Intents en el target Runner para que el sistema los ejecute al pulsar botones en la Live Activity.
@available(iOS 17.0, *)
struct LactationAppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PauseLactationIntent(),
            phrases: [
                "Pausar lactancia en \(.applicationName)",
                "Pausar toma en \(.applicationName)",
            ],
            shortTitle: "Pausar lactancia",
            systemImageName: "pause.fill"
        )
        AppShortcut(
            intent: ResumeLactationIntent(),
            phrases: [
                "Reanudar lactancia en \(.applicationName)",
                "Reanudar toma en \(.applicationName)",
            ],
            shortTitle: "Reanudar lactancia",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StopLactationIntent(),
            phrases: [
                "Parar lactancia en \(.applicationName)",
                "Parar toma en \(.applicationName)",
            ],
            shortTitle: "Parar lactancia",
            systemImageName: "stop.fill"
        )
    }
}
