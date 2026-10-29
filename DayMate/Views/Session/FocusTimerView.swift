//
//  FocusTimerView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il timer del RISCALDAMENTO (2-3 minuti).
//
//  Perché così corto? Il Pomodoro classico chiede 25 minuti: troppi se sei bloccato.
//  Qui l'obiettivo NON è studiare tanto, è superare la soglia d'ingresso.
//  Spesso, una volta partiti, si continua da soli (e la schermata dopo lo permette).
//

import SwiftUI

struct FocusTimerView: View {
    let step: PlannedStep
    /// Callback: (secondi studiati, l'utente ha premuto "Fatto"?)
    var onFinish: (_ elapsedSeconds: Int, _ markedDone: Bool) -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var countdown = Countdown()
    @State private var started = false
    @State private var finished = false

    var body: some View {
        TimerScreen(
            eyebrow: tr("Warm-up", "Riscaldamento"),
            title: step.text,
            progress: countdown.progress,
            active: true,
            pose: .reading,
            time: countdown.remaining.mmss,
            caption: tr("Lock your phone and put it away: I'll let you know.",
                        "Blocca pure il telefono e mettilo via: ti avviso io.")
        ) {
            EmptyView()
        } buttons: {
            Button {
                finish(markedDone: true)
            } label: {
                Label(tr("Done!", "Fatto!"), systemImage: "checkmark")
            }
            .buttonStyle(PillButtonStyle(variant: .dark))

            Button(tr("I'll stop earlier, that's fine", "Mi fermo prima, va bene così")) {
                finish(markedDone: false)
            }
            .buttonStyle(TextLinkStyle())
        }
        // .onAppear viene chiamato quando la schermata compare
        .onAppear(perform: startIfNeeded)
        .onDisappear {
            countdown.stop()
            NotificationManager.shared.cancel(id: NotificationManager.focusID)
        }
    }

    /// Avvio una sola volta (onAppear in alcuni casi può essere chiamato due volte)
    private func startIfNeeded() {
        guard !started else { return }
        started = true

        let seconds = TimeInterval(step.minutes * 60)
        countdown.onFinish = {
            finish(markedDone: false)
        }
        countdown.start(seconds: seconds)

        NotificationManager.shared.schedule(
            id: NotificationManager.focusID,
            title: tr("Time's up! ⏰", "Tempo! ⏰"),
            body: tr("You did \(step.minutes) minutes. Keep going or take a real break?",
                     "Hai fatto \(step.minutes) minuti. Continui o fai una pausa vera?"),
            after: seconds
        )
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
    FocusTimerView(step: PlannedStep(text: "Read the first page of «Limits»", minutes: 2, step: nil)) { _, _ in }
}
