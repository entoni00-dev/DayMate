//
//  FocusTimerView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il timer del RISCALDAMENTO (solo per "Stuck": "Easier step first").
//  Stessa grafica del timer di studio, ma dura 2 minuti e chiede un gesto minuscolo
//  ("apri il libro alla pagina giusta"). L'obiettivo NON è studiare: è superare la
//  soglia d'ingresso. Spesso, una volta partiti, si continua da soli.
//

import SwiftUI

struct FocusTimerView: View {
    let step: PlannedStep
    /// Callback: (secondi passati, l'utente ha premuto "Fatto"?)
    var onFinish: (_ elapsedSeconds: Int, _ markedDone: Bool) -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var countdown = Countdown()
    @State private var started = false
    @State private var finished = false

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(tr("Easier step first · \(step.minutes) min", "Prima un passo facilissimo · \(step.minutes) min"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.accent)
                Text(step.text)
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 8)

            TimerRing(progress: countdown.progress, time: countdown.remaining.mmss)

            Text(tr("Just this. Nothing more.", "Solo questo. Niente di più."))
                .font(.subheadline)
                .foregroundStyle(Theme.secondary)

            Spacer(minLength: 8)

            RoundTimerButton(systemName: "checkmark", prominent: true,
                             accessibilityTitle: tr("Done", "Fatto")) {
                finish(markedDone: true)
            }

            Button(tr("I'll stop here, that's fine", "Mi fermo qui, va bene così")) {
                finish(markedDone: false)
            }
            .buttonStyle(QuietButtonStyle())
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // .onAppear viene chiamato quando la schermata compare
        .onAppear(perform: startIfNeeded)
        .onDisappear {
            countdown.stop()
            NotificationManager.shared.cancel(id: NotificationManager.focusID)
            LiveActivityManager.shared.end(isBreak: false)
        }
    }

    /// Avvio una sola volta (onAppear in alcuni casi può essere chiamato due volte)
    private func startIfNeeded() {
        guard !started else { return }
        started = true

        let seconds = TimeInterval(step.minutes * 60)
        countdown.onFinish = { finish(markedDone: false) }
        countdown.start(seconds: seconds)

        NotificationManager.shared.schedule(
            id: NotificationManager.focusID,
            title: tr("Time's up! ⏰", "Tempo! ⏰"),
            body: tr("You did \(step.minutes) minutes. Keep going or take a real break?",
                     "Hai fatto \(step.minutes) minuti. Continui o fai una pausa vera?"),
            after: seconds
        )
        // 🏝️ anche il riscaldamento si vede sulla schermata di blocco
        LiveActivityManager.shared.start(examName: "",
                                         title: step.text,
                                         subtitle: tr("Easier step first", "Prima un passo facilissimo"),
                                         footer: tr("Just this. Nothing more.", "Solo questo. Niente di più."),
                                         isBreak: false,
                                         seconds: seconds)
    }

    private func finish(markedDone: Bool) {
        guard !finished else { return }
        finished = true
        countdown.stop()
        NotificationManager.shared.cancel(id: NotificationManager.focusID)
        Haptics.success()
        onFinish(Int(countdown.elapsed), markedDone)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    FocusTimerView(step: PlannedStep(text: "Open the book at the right page", minutes: 2, step: nil)) { _, _ in }
        .background(Theme.background)
}
