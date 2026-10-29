//
//  FocusBlockView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il blocco di studio vero e proprio ("Timer pt.2" di Sketch: anello giallo,
//  il bradipo con gli occhiali che legge).
//
//  Due "orologi" diversi, e non vanno confusi:
//   ⏱️ il TIMER DEL BLOCCO (grande anello): quanto manca alla pausa
//   ⌛️ il tempo sul PASSO corrente: serve all'app per imparare quanto ci metti davvero
//
//  Dentro un blocco fai i passi uno dopo l'altro ("Step done ✓ → prossimo")
//  senza fermare il timer. Quando il timer finisce: ⏸️ Time for a break!
//

import SwiftUI

struct FocusBlockView: View {
    let model: StudySessionModel

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var countdown = Countdown()
    @State private var started = false
    @State private var finished = false
    @State private var blockMinutes = 0

    // Parcheggio dubbi
    @State private var showingDoubt = false
    @State private var doubtText = ""
    @State private var doubtSaved = false

    var body: some View {
        TimerScreen(
            eyebrow: tr("Block \(model.blocksDone + 1) · step \(model.stepNumber) of \(model.stepTotal)",
                        "Blocco \(model.blocksDone + 1) · passo \(model.stepNumber) di \(model.stepTotal)"),
            title: model.currentStep?.title ?? "",
            subtitle: model.currentStep.map { step in
                tr("≈ \(model.exam.estimatedMinutes(for: step)) min · on this step for \(TimeInterval(model.currentStepSeconds).mmss)",
                   "≈ \(model.exam.estimatedMinutes(for: step)) min · su questo passo da \(TimeInterval(model.currentStepSeconds).mmss)")
            },
            progress: countdown.progress,
            active: true,
            pose: .reading,
            time: countdown.remaining.mmss,
            caption: tr("until your break", "alla pausa")
        ) {
            if let step = model.currentStep {
                StepTipView(step: step)
                    // .id: quando cambia passo il consiglio si richiude
                    .id(step.persistentModelID)
            }
        } buttons: {
            Button {
                completeStep()
            } label: {
                Label(tr("Step done, next", "Passo fatto, avanti"), systemImage: "checkmark")
            }
            .buttonStyle(PillButtonStyle(variant: .dark))

            Button(tr("Have a break", "Fai una pausa")) { finish(.breakNow) }
                .buttonStyle(PillButtonStyle(variant: .honey))

            HStack(spacing: 24) {
                Button {
                    showingDoubt = true
                } label: {
                    Label(doubtSaved ? tr("Saved!", "Salvato!") : tr("Doubt", "Dubbio"),
                          systemImage: doubtSaved ? "checkmark" : "bubble.left.and.exclamationmark.bubble.right")
                }
                .buttonStyle(TextLinkStyle(color: Theme.rust))

                Button(tr("Stop for today", "Basta per oggi")) { finish(.stop) }
                    .buttonStyle(TextLinkStyle())
            }
        }
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
            Text(tr("Write it down and move on: you'll find it later in Study → Doubts. So you don't get stuck or grab your phone to look it up.",
                    "Scrivilo e vai avanti: lo ritrovi dopo in Studio → Dubbi. Così non ti blocchi e non prendi il telefono per cercarlo."))
        }
    }

    // MARK: - Azioni

    private func startIfNeeded() {
        guard !started else { return }
        started = true

        blockMinutes = model.nextBlockMinutes
        let seconds = TimeInterval(blockMinutes * 60)

        model.blockDidStart()
        countdown.onFinish = { finish(.timeUp) }
        countdown.start(seconds: seconds)

        // Se il telefono è bloccato, l'avviso arriva come notifica con il suo suono
        NotificationManager.shared.scheduleBreakTime(
            after: seconds,
            studiedMinutes: blockMinutes,
            breakMinutes: StudyRhythm.breakMinutes(afterBlocks: model.blocksDone + 1)
        )
    }

    private func completeStep() {
        Haptics.success()
        var hasMore = true
        // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
        withAnimation(.spring(response: 0.4)) {
            hasMore = model.completeCurrentStep()
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
