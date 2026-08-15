import AppIntents
import ActivityKit
import SwiftUI
import WidgetKit

private let lactationSharedDefaults = UserDefaults(suiteName: "group.com.controlbebe.controlBebe.liveactivity")!

/// Misma referencia que el azul biberón / Material en la app (`#2196F3`).
private let appBrandBlue = Color(red: 33 / 255, green: 150 / 255, blue: 243 / 255)
/// Mismo verde que `AppTheme.primaryGreen` al guardar una toma.
private let appSavedGreen = Color(red: 45 / 255, green: 106 / 255, blue: 79 / 255)

@main
struct LactationLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        LactationTimerLiveActivityWidget()
    }
}

@available(iOSApplicationExtension 16.1, *)
struct LactationTimerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            lactationLockScreen(context: context)
        } dynamicIsland: { context in
            lactationDynamicIsland(context: context)
        }
    }

    @ViewBuilder
    private func lactationLockScreen(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> some View {
        let attrs = context.attributes
        let side = lactationSharedDefaults.string(forKey: attrs.prefixedKey("sideLabel")) ?? "—"
        let isPaused = lactationBool(attrs, key: "isPaused")
        let frozenMs = lactationDouble(attrs, key: "frozenElapsedMs")
        let confirmPhase = lactationSharedDefaults.string(forKey: attrs.prefixedKey("confirmPhase")) ?? "idle"
        let startedAt = lactationEffectiveStartDate(context: context, isPaused: isPaused)
        let endAt = startedAt.addingTimeInterval(60 * 60 * 48)

        HStack {
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Link(destination: URL(string: "mibebe://feeding")!) {
                            Text("MiBebé")
                                .font(.headline)
                                .foregroundStyle(appBrandBlue)
                        }
                        Text(side)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    lactationElapsedTimer(
                        isPaused: isPaused,
                        frozenMs: frozenMs,
                        startedAt: startedAt,
                        endAt: endAt,
                        font: .title3
                    )
                }
                lactationControlButtons(
                    attrs: attrs,
                    isPaused: isPaused,
                    compact: false,
                    confirmPhase: confirmPhase
                )
            }
            .frame(maxWidth: 340)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private func lactationDynamicIsland(context: ActivityViewContext<LiveActivitiesAppAttributes>) -> DynamicIsland {
        let attrs = context.attributes
        let confirmPhase = lactationSharedDefaults.string(forKey: attrs.prefixedKey("confirmPhase")) ?? "idle"
        let isPaused = lactationBool(attrs, key: "isPaused")
        let frozenMs = lactationDouble(attrs, key: "frozenElapsedMs")
        let startedAt = lactationEffectiveStartDate(context: context, isPaused: isPaused)
        let endAt = startedAt.addingTimeInterval(60 * 60 * 48)

        return DynamicIsland {
            DynamicIslandExpandedRegion(.center) {
                VStack(alignment: .leading, spacing: 12) {
                    Link(destination: URL(string: "mibebe://feeding")!) {
                        Text("MiBebé")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(appBrandBlue)
                            .lineLimit(1)
                    }
                    HStack(alignment: .center, spacing: 14) {
                        Image(systemName: "timer")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(appBrandBlue)
                        Text(lactationExpandedSideLabel(attributes: attrs))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        lactationElapsedTimer(
                            isPaused: isPaused,
                            frozenMs: frozenMs,
                            startedAt: startedAt,
                            endAt: endAt,
                            font: .system(size: 22, weight: .semibold, design: .rounded)
                        )
                    }
                    lactationControlButtons(
                        attrs: attrs,
                        isPaused: isPaused,
                        compact: true,
                        confirmPhase: confirmPhase
                    )
                }
                .frame(maxWidth: 320, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 8)
            }
        } compactLeading: {
            Image(systemName: isPaused ? "pause.circle.fill" : "timer")
                .font(.system(size: 15, weight: .semibold))
                .imageScale(.medium)
                .foregroundStyle(appBrandBlue)
        } compactTrailing: {
            lactationElapsedTimer(
                isPaused: isPaused,
                frozenMs: frozenMs,
                startedAt: startedAt,
                endAt: endAt,
                font: .system(size: 15, weight: .semibold, design: .rounded),
                fixedWidth: 50
            )
        } minimal: {
            Image(systemName: isPaused ? "pause.circle.fill" : "timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(appBrandBlue)
        }
    }

    @ViewBuilder
    private func lactationControlButtons(
        attrs: LiveActivitiesAppAttributes,
        isPaused: Bool,
        compact: Bool,
        confirmPhase: String
    ) -> some View {
        let isSaved = confirmPhase == "saved"
        let pauseLabel = lactationSharedDefaults.string(forKey: attrs.prefixedKey("pauseLabel")) ?? "Pausa"
        let resumeLabel = lactationSharedDefaults.string(forKey: attrs.prefixedKey("resumeLabel")) ?? "Reanudar"
        let labelFont = compact
            ? Font.caption.weight(.semibold)
            : Font.subheadline.weight(.semibold)
        let buttonHeight = compact ? CGFloat(34) : CGFloat(40)

        HStack(alignment: .center, spacing: compact ? 8 : 12) {
            lactationPauseButton(
                isPaused: isPaused,
                isSaved: isSaved,
                pauseLabel: pauseLabel,
                resumeLabel: resumeLabel,
                labelFont: labelFont,
                buttonHeight: buttonHeight
            )
            lactationStopButton(
                attrs: attrs,
                confirmPhase: confirmPhase,
                compact: compact,
                buttonHeight: buttonHeight
            )
        }
    }

    @ViewBuilder
    private func lactationPauseButton(
        isPaused: Bool,
        isSaved: Bool,
        pauseLabel: String,
        resumeLabel: String,
        labelFont: Font,
        buttonHeight: CGFloat
    ) -> some View {
        let chrome = RoundedRectangle(cornerRadius: 10, style: .continuous)
        let fill = isSaved ? appBrandBlue.opacity(0.06) : appBrandBlue.opacity(0.12)
        let foreground = isSaved ? appBrandBlue.opacity(0.35) : appBrandBlue

        Group {
            if isSaved {
                Label(
                    isPaused ? resumeLabel : pauseLabel,
                    systemImage: isPaused ? "play.fill" : "pause.fill"
                )
                .font(labelFont)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            } else if #available(iOS 17.0, *) {
                if isPaused {
                    Button(intent: ResumeLactationIntent()) {
                        Label(resumeLabel, systemImage: "play.fill")
                            .font(labelFont)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(intent: PauseLactationIntent()) {
                        Label(pauseLabel, systemImage: "pause.fill")
                            .font(labelFont)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                let pauseUrl = isPaused ? "mibebe://lactation/resume" : "mibebe://lactation/pause"
                Link(destination: URL(string: pauseUrl)!) {
                    Label(isPaused ? resumeLabel : pauseLabel, systemImage: isPaused ? "play.fill" : "pause.fill")
                        .font(labelFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: buttonHeight)
        .background(fill)
        .clipShape(chrome)
    }

    /// Parar: verde + check (saved) sin cambiar el ancho de la fila.
    @ViewBuilder
    private func lactationStopButton(
        attrs: LiveActivitiesAppAttributes,
        confirmPhase: String,
        compact: Bool,
        buttonHeight: CGFloat
    ) -> some View {
        let stopLabel = lactationSharedDefaults.string(forKey: attrs.prefixedKey("stopLabel")) ?? "Parar"
        let savedLabel = lactationSharedDefaults.string(forKey: attrs.prefixedKey("savedLabel")) ?? "Guardado"
        let labelFont = compact
            ? Font.caption.weight(.semibold)
            : Font.subheadline.weight(.semibold)
        let chrome = RoundedRectangle(cornerRadius: 10, style: .continuous)
        let isSaved = confirmPhase == "saved"

        Group {
            if isSaved {
                Label(savedLabel, systemImage: "checkmark.circle.fill")
                    .font(labelFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } else if #available(iOS 17.0, *) {
                Button(intent: StopLactationIntent()) {
                    Label(stopLabel, systemImage: "stop.fill")
                        .font(labelFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .buttonStyle(.plain)
            } else {
                Link(destination: URL(string: "mibebe://lactation/stop")!) {
                    Label(stopLabel, systemImage: "stop.fill")
                        .font(labelFont)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: buttonHeight)
        .background(isSaved ? appSavedGreen : appBrandBlue)
        .clipShape(chrome)
    }

    private func lactationEffectiveStartDate(
        context: ActivityViewContext<LiveActivitiesAppAttributes>,
        isPaused: Bool
    ) -> Date {
        let attrs = context.attributes
        let ms = lactationSharedDefaults.double(forKey: attrs.prefixedKey("startedAtMs"))
        let totalPausedMs = lactationDouble(attrs, key: "totalPausedMs")
        if ms <= 0 { return Date() }
        let base = ms / 1000.0 + totalPausedMs / 1000.0
        return Date(timeIntervalSince1970: base)
    }

    private func lactationBool(_ attrs: LiveActivitiesAppAttributes, key: String) -> Bool {
        let k = attrs.prefixedKey(key)
        if let o = lactationSharedDefaults.object(forKey: k) {
            if let b = o as? Bool { return b }
            if let n = o as? NSNumber { return n.boolValue }
        }
        return false
    }

    private func lactationDouble(_ attrs: LiveActivitiesAppAttributes, key: String) -> Double {
        lactationSharedDefaults.double(forKey: attrs.prefixedKey(key))
    }

    /// `Text(timerInterval:)` no respeta `Spacer` como un `Text` estático; forzamos trailing.
    @ViewBuilder
    private func lactationElapsedTimer(
        isPaused: Bool,
        frozenMs: Double,
        startedAt: Date,
        endAt: Date,
        font: Font,
        fixedWidth: CGFloat? = nil
    ) -> some View {
        Group {
            if isPaused {
                Text(formatElapsedMs(frozenMs))
            } else {
                Text(timerInterval: startedAt...endAt, countsDown: false)
            }
        }
        .font(font)
        .monospacedDigit()
        .foregroundStyle(appBrandBlue)
        .lineLimit(1)
        .multilineTextAlignment(.trailing)
        .frame(
            maxWidth: fixedWidth == nil ? .infinity : fixedWidth,
            alignment: .trailing
        )
    }

    private func formatElapsedMs(_ ms: Double) -> String {
        let total = max(0, Int(ms / 1000.0))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    /// `sideIsLeft` lo envía Flutter; si falta (actividad antigua), se intenta inferir del `sideLabel`.
    private func lactationExpandedSideLabel(attributes: LiveActivitiesAppAttributes) -> String {
        let boolKey = attributes.prefixedKey("sideIsLeft")
        if let o = lactationSharedDefaults.object(forKey: boolKey) {
            if let b = o as? Bool { return b ? "Izquierdo" : "Derecho" }
            if let n = o as? NSNumber { return n.boolValue ? "Izquierdo" : "Derecho" }
        }
        let side = lactationSharedDefaults.string(forKey: attributes.prefixedKey("sideLabel")) ?? ""
        let lower = side.lowercased()
        if lower.contains("izquierd") || lower.contains("left") { return "Izquierdo" }
        if lower.contains("derech") || lower.contains("right") { return "Derecho" }
        return "—"
    }
}
