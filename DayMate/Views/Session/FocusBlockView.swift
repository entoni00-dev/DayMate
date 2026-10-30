//
//  FocusBlockView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il timer di studio (schermata 05 di Sketch):
//
//        Math · step 3 of 6
//           Read Ch. 2
//          ( anello 3:42 )
//     Phone down, one tiny step.
//            ⏸      ✓
//
//  Due "orologi" diversi, e non vanno confusi:
//   ⏱️ il TIMER DEL BLOCCO (l'anello): quanto manca alla pausa
//   ⌛️ il tempo sul PASSO corrente: serve all'app per imparare quanto ci metti davvero
//
//  ✓ = "passo fatto": si passa al prossimo passo SENZA fermare il timer.
//  Quando il timer finisce si va alla pausa ("Break time").
//

import SwiftUI

struct FocusBlockView: View {
    let model: StudySessionModel

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var countdown = Countdown()
    @State private var started = false
    @State private var finished = false
    @State private var blockMinutes = 0
    @State private var showTip = false

    // Parcheggio dubbi
    @State private var showingDoubt = false
    @State private var doubtText = ""
    @State private var doubtSaved = false

    var body: some View {
        VStack(spacing: 18) {
            // Titolo: esame, numero del passo e cosa fare
            VStack(spacing: 6) {
                Text("\(model.exam.name) · " + tr("step \(model.stepNumber) of \(model.stepTotal)",
                                                  "passo \(model.stepNumber) di \(model.stepTotal)"))
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                Text(model.currentStep?.title ?? "")
                    .font(.dmTitle)
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 8)

            TimerRing(progress: countdown.progress, time: countdown.remaining.mmss)

            Text(countdown.isPaused ? tr("Paused. Take your time.", "In pausa. Con calma.")
                                    : tr("Phone down, one tiny step.", "Telefono giù, un piccolo passo."))
                .font(.subheadline)
                .foregroundStyle(Theme.secondary)

            // Il consiglio del passo, aperto solo se lo chiedo
            if showTip, let step = model.currentStep {
                Text(step.kind.tip)
                    .font(.footnote)
                    .foregroundStyle(Theme.text)
                    .padding(14)
                    .cardBackground(radius: 16)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            }

            Spacer(minLength: 8)

            // ⏸ / ▶︎ e ✓
            HStack(spacing: 28) {
                RoundTimerButton(systemName: countdown.isPaused ? "play.fill" : "pause.fill",
                                 accessibilityTitle: countdown.isPaused ? tr("Resume", "Riprendi") : tr("Pause", "Pausa"),
                                 action: togglePause)
                RoundTimerButton(systemName: "checkmark", prominent: true,
                                 accessibilityTitle: tr("Step done", "Passo fatto"),
                                 action: completeStep)
            }

            // Le azioni meno usate, piccole e discrete
            HStack(spacing: 18) {
                Button {
                    withAnimation { showTip.toggle() }
                } label: {
                    Label(tr("Tip", "Consiglio"), systemImage: "lightbulb")
                }
                Button {
                    showingDoubt = true
                } label: {
                    Label(doubtSaved ? tr("Saved!", "Salvato!") : tr("Doubt", "Dubbio"),
                          systemImage: doubtSaved ? "checkmark" : "questionmark.bubble")
                }
                Button {
                    finish(.breakNow)
                } label: {
                    Label(tr("Break", "Pausa"), systemImage: "cup.and.saucer")
                }
                Button(tr("Stop", "Basta")) { finish(.stop) }
            }
            .buttonStyle(QuietButtonStyle())
            .font(.footnote)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // .onAppear viene chiamato quando la schermata compare
        .onAppear(perform: startIfNeeded)
        .onDisappear {
            countdown.stop()
            NotificationManager.shared.cancel(id: NotificationManager.focusID)
        }
        .alert(tr("Park your doubt", "Parcheggia il dubbio"), isPresented: $showingDoubt) {
            TextField(tr("E.g. Why does the limit equal 1?", "Es. Perché il limite fa 1?"), text: $doubtText)
            Button(tr("Save", "Salva")) { saveDoubt() }
            Button(tr("Cancel", "Annulla"), role: .cancel) { doubtText = "" }
        } message: {
            Text(tr("Write it down and keep going: you'll find it later in Doubts.",
                    "Scrivilo e vai avanti: lo ritrovi dopo in Dubbi."))
        }
    }

    // MARK: - Azioni

    private func startIfNeeded() {
        // onAppear a volte viene chiamato due volte: faccio partire il timer una volta sola
        guard !started else { return }
        started = true

        blockMinutes = model.nextBlockMinutes
        let seconds = TimeInterval(blockMinutes * 60)

        model.blockDidStart()
        countdown.onFinish = { finish(.timeUp) }
        countdown.start(seconds: seconds)
        scheduleNotification(after: seconds)
    }

    /// Se il telefono è bloccato, la fine del blocco arriva come notifica con il suo suono
    private func scheduleNotification(after seconds: TimeInterval) {
        NotificationManager.shared.scheduleBreakTime(
            after: seconds,
            studiedMinutes: blockMinutes,
            breakMinutes: StudyRhythm.breakMinutes(afterBlocks: model.blocksDone + 1)
        )
    }

    private func togglePause() {
        if countdown.isPaused {
            countdown.resume()
            scheduleNotification(after: countdown.remaining)   // rimetto la notifica col tempo che manca
        } else {
            countdown.pause()
            NotificationManager.shared.cancel(id: NotificationManager.focusID)
        }
    }

    private func completeStep() {
        Haptics.success()
        var hasMore = true
        withAnimation(.spring(response: 0.4)) {
            hasMore = model.completeCurrentStep()
            showTip = false
        }
        if !hasMore { finish(.allDone) }
    }

    private func finish(_ reason: StudySessionModel.BlockEnd) {
        guard !finished else { return }
        finished = true
        countdown.stop()
        NotificationManager.shared.cancel(id: NotificationManager.focusID)
        model.endBlock(elapsedSeconds: Int(countdown.elapsed), reason: reason)
    }

    private func saveDoubt() {
        model.parkDoubt(doubtText)
        doubtText = ""
        Haptics.tap()
        withAnimation { doubtSaved = true }
        // Dopo 2 secondi il bottone torna normale
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { doubtSaved = false }
        }
    }
}
