//
//  DayMateWidgetLiveActivity.swift
//  DayMateWidget
//
//  Created by Antonio Carotenuto.
//
//  🏝️ COME SI VEDE la Live Activity del timer.
//
//  Schermata di blocco:
//   ┌────────────────────────────────────────────┐
//   │ (◔📖)  Math · step 3 of 6            12:34 │
//   │        Read Ch. 2                          │
//   │        Phone down, one tiny step.          │
//   └────────────────────────────────────────────┘
//
//  Dynamic Island (iPhone 14 Pro e successivi):
//   compatta:  📖 ●●●●●●●●●●●●●●●●●● 12:34
//   aperta (tenendo premuto): anello, titolo, tempo grande
//
//  📌 Nota per me: il tempo lo fa scorrere iOS con Text(timerInterval:). Io gli dico solo
//  "da quando a quando" e lui aggiorna i secondi, anche con l'app chiusa.
//  L'estensione NON vede Theme.swift (è un altro target), quindi i colori li riscrivo qui.
//

import ActivityKit
import WidgetKit
import SwiftUI

/// I colori di Ube night (uguali a Theme.swift)
private enum Ube {
    static let background = Color(red: 26 / 255, green: 21 / 255, blue: 48 / 255)    // #1A1530
    static let highlight  = Color(red: 51 / 255, green: 42 / 255, blue: 92 / 255)    // #332A5C
    static let accent     = Color(red: 126 / 255, green: 240 / 255, blue: 200 / 255) // #7EF0C8
    static let text       = Color(red: 241 / 255, green: 237 / 255, blue: 255 / 255) // #F1EDFF
    static let secondary  = Color(red: 152 / 255, green: 144 / 255, blue: 191 / 255) // #9890BF
}

struct StudyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StudyActivityAttributes.self) { context in
            // 🔒 Schermata di blocco (e banner sugli iPhone senza Dynamic Island)
            LockScreenView(state: context.state)
                .activityBackgroundTint(Ube.background)
                .activitySystemActionForegroundColor(Ube.accent)

        } dynamicIsland: { context in
            DynamicIsland {
                // Dynamic Island APERTA (tenendo premuto sulla "pillola")
                DynamicIslandExpandedRegion(.leading) {
                    TimerRingIcon(state: context.state)
                        .frame(width: 44, height: 44)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimeText(state: context.state)
                        .font(.system(.title, weight: .bold))
                        .foregroundStyle(Ube.accent)
                        .frame(maxWidth: 110, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.subtitle)
                            .font(.caption)
                            .foregroundStyle(Ube.secondary)
                        Text(context.state.title)
                            .font(.headline)
                            .foregroundStyle(Ube.text)
                            .lineLimit(1)
                        Text(context.state.footer)
                            .font(.caption)
                            .foregroundStyle(Ube.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                // Dynamic Island compatta: a sinistra l'icona…
                Image(systemName: context.state.isBreak ? "cup.and.saucer.fill" : "book.fill")
                    .foregroundStyle(Ube.accent)
            } compactTrailing: {
                // …e a destra il tempo. La larghezza fissa evita che il testo "spinga" l'isola
                TimeText(state: context.state)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Ube.accent)
                    .frame(width: 48)
            } minimal: {
                // Quando ci sono due Live Activity insieme: solo l'anello
                TimerRingIcon(state: context.state)
            }
            .keylineTint(Ube.accent)
        }
    }
}

// MARK: - Pezzi riutilizzati

/// La schermata di blocco
private struct LockScreenView: View {
    let state: StudyActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            TimerRingIcon(state: state)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Ube.secondary)
                Text(state.title)
                    .font(.headline)
                    .foregroundStyle(Ube.text)
                    .lineLimit(1)
                Text(state.footer)
                    .font(.caption)
                    .foregroundStyle(Ube.secondary)
            }

            Spacer(minLength: 8)

            TimeText(state: state)
                .font(.system(.title, weight: .bold))
                .foregroundStyle(Ube.accent)
                .frame(maxWidth: 100, alignment: .trailing)
        }
        .padding(16)
    }
}

/// Il tempo che manca: scorre da solo, oppure è fermo se ho premuto ⏸
private struct TimeText: View {
    let state: StudyActivityAttributes.ContentState

    var body: some View {
        if let paused = state.pausedRemaining {
            // in pausa: un numero fermo, es. "12:34"
            let seconds = Int(paused.rounded(.up))
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .monospacedDigit()
        } else {
            // in corso: iOS fa scorrere il conto alla rovescia da solo
            Text(timerInterval: state.startDate...max(state.startDate, state.endDate), countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
    }
}

/// L'anello verde con l'icona al centro (libro = studio, tazza = pausa)
private struct TimerRingIcon: View {
    let state: StudyActivityAttributes.ContentState

    var body: some View {
        ZStack {
            if let paused = state.pausedRemaining {
                // in pausa l'anello resta fermo dov'era
                ProgressView(value: max(0, min(1, 1 - paused / max(state.total, 1))))
                    .progressViewStyle(.circular)
            } else {
                // in corso l'anello si riempie da solo, come il timer nell'app
                ProgressView(timerInterval: state.startDate...max(state.startDate, state.endDate),
                             countsDown: false,
                             label: { EmptyView() },
                             currentValueLabel: { EmptyView() })
                    .progressViewStyle(.circular)
            }
            Image(systemName: state.isBreak ? "cup.and.saucer.fill" : "book.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Ube.text)
        }
        .tint(Ube.accent)
    }
}

// Anteprima per il canvas di Xcode: com'è sulla schermata di blocco
#Preview("Schermata di blocco", as: .content, using: StudyActivityAttributes(examName: "Math")) {
    StudyLiveActivity()
} contentStates: {
    StudyActivityAttributes.ContentState(
        title: "Read Ch. 2", subtitle: "Math · step 3 of 6", footer: "Phone down, one tiny step.",
        isBreak: false, startDate: .now, endDate: .now.addingTimeInterval(25 * 60),
        pausedRemaining: nil, total: 25 * 60)
    StudyActivityAttributes.ContentState(
        title: "Short walk", subtitle: "Break time", footer: "Paused",
        isBreak: true, startDate: .now, endDate: .now.addingTimeInterval(5 * 60),
        pausedRemaining: 180, total: 300)
}
