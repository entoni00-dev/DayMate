//
//  StudySessionModel.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il "cervello" della sessione di studio (pattern MVVM: questo è il ViewModel).
//
//  🔄 Versione 2: nella v1 la logica stava dentro SessionFlowView con tanti @State.
//  Con il nuovo ritmo studio/pausa le cose da ricordare sono aumentate (blocchi fatti,
//  passo corrente, tempo reale del passo...), quindi ho spostato tutto in una classe
//  @Observable. Le viste mostrano lo stato e chiamano metodi; le decisioni stanno qui.
//
//  🔁 Il ciclo completo:
//
//   checkIn ─► [riscaldamento → scelta] ─► ready ─► BLOCCO ─► ⏸️ "È TEMPO DI UNA PAUSA"
//                (solo se ansia/blocco)        ▲                          │
//                                              │                          ▼
//                                   ▶️ "ORA SI TORNA A STUDIARE" ◄── pausa vera
//
//   In ogni momento: "mi fermo" ─► checkOut (umore) ─► riepilogo
//

import Foundation
import SwiftData
import Observation

@Observable
final class StudySessionModel {

    enum Phase: Hashable {
        case checkIn        // come ti senti?
        case warmUpPreview  // il passo minuscolo (solo ansia/bloccato)
        case warmUp         // timer del riscaldamento (2-3 min)
        case choice         // continuo / pausa / mi fermo
        case ready          // "Blocco N: X minuti" + primo passo → Via!
        case block          // blocco di studio con timer
        case pauseAlert     // ⏸️ È TEMPO DI UNA PAUSA
        case breakTime      // pausa vera
        case studyAlert     // ▶️ ORA SI TORNA A STUDIARE
        case checkOut       // come ti senti ora?
        case summary        // riepilogo
    }

    /// Come è finito un blocco
    enum BlockEnd {
        case timeUp      // timer scaduto → avviso pausa
        case breakNow    // l'utente ha chiesto una pausa prima
        case stop        // l'utente si ferma
        case allDone     // passi finiti!
    }

    let exam: Exam

    private(set) var phase: Phase = .checkIn
    private(set) var mood: Mood = .great
    private(set) var session: StudySession?
    private(set) var warmUp: PlannedStep?
    private(set) var currentStep: StudyStep?
    private(set) var blocksDone = 0
    private(set) var lastBlockMinutes = 0
    private(set) var lastWarmUpSeconds = 0
    private(set) var allDone = false

    /// Quando ho iniziato il passo corrente (per misurare il tempo reale)
    private(set) var stepStartedAt: Date?

    @ObservationIgnored private var context: ModelContext?

    init(exam: Exam) {
        self.exam = exam
    }

    // MARK: - Valori calcolati per le viste

    /// Durata del prossimo blocco (segue la rampa in base all'umore)
    var nextBlockMinutes: Int {
        StudyRhythm.blockMinutes(index: blocksDone, mood: mood)
    }

    /// Durata della pausa che segue i blocchi già fatti
    var breakMinutes: Int {
        StudyRhythm.breakMinutes(afterBlocks: blocksDone)
    }

    /// È la pausa lunga (ogni 4 blocchi)?
    var isLongBreak: Bool {
        blocksDone > 0 && blocksDone % 4 == 0
    }

    /// "step 3 of 6": numero del passo corrente e totale dei passi dell'esame
    var stepNumber: Int { min(exam.doneCount + 1, max(exam.steps.count, 1)) }
    var stepTotal: Int { exam.steps.count }

    /// Si può ancora tornare alla scelta dell'umore? Solo se non è stato fatto niente.
    var canGoBackToMood: Bool {
        blocksDone == 0 && (session?.focusedSeconds ?? 0) == 0 && (session?.stepsCompleted ?? 0) == 0
    }

    /// Secondi passati sul passo corrente (si aggiorna quando la vista si ridisegna)
    var currentStepSeconds: Int {
        guard let stepStartedAt else { return 0 }
        return Int(Date().timeIntervalSince(stepStartedAt))
    }

    // MARK: - Check-in

    func checkIn(_ selected: Mood, context: ModelContext) {
        mood = selected
        self.context = context

        let newSession = StudySession(moodBefore: selected)
        context.insert(newSession)
        newSession.exam = exam
        session = newSession

        currentStep = exam.nextStep

        if currentStep == nil {
            // Non c'è niente da fare: tutti i passi sono già completati
            allDone = true
            phase = .checkOut
        } else if let warm = FirstStepPicker.warmUp(for: selected, next: currentStep) {
            warmUp = warm
            phase = .warmUpPreview
        } else {
            phase = .ready
        }
    }

    /// "‹ Mood": torno alla scelta dell'umore senza lasciare una sessione vuota
    func backToCheckIn() {
        guard canGoBackToMood else { return }
        if let session { context?.delete(session) }
        session = nil
        warmUp = nil
        stepStartedAt = nil
        phase = .checkIn
    }

    // MARK: - Riscaldamento

    func shrinkWarmUp() {
        warmUp = FirstStepPicker.tinyStep(minutes: 2)
    }

    func startWarmUp() {
        phase = .warmUp
    }

    func warmUpFinished(elapsedSeconds: Int) {
        session?.focusedSeconds += elapsedSeconds
        lastWarmUpSeconds = elapsedSeconds
        phase = .choice
    }

    // MARK: - Scelte dell'utente

    func continueStudying() {
        phase = currentStep == nil ? .checkOut : .ready
    }

    func takeBreak() {
        phase = .breakTime
    }

    func stop() {
        phase = .checkOut
    }

    // MARK: - Blocco di studio

    func startBlock() {
        phase = .block
    }

    /// Chiamato quando la schermata del blocco appare: parte il cronometro del passo
    func blockDidStart() {
        if stepStartedAt == nil { stepStartedAt = .now }
    }

    /// Segna il passo corrente come completato e carica il successivo.
    /// - Returns: false se non ci sono altri passi (esame completato!)
    @discardableResult
    func completeCurrentStep() -> Bool {
        guard let step = currentStep else { return false }
        recordStepTime()
        step.isDone = true
        step.completedAt = .now
        session?.stepsCompleted += 1

        currentStep = exam.nextStep
        if currentStep != nil {
            stepStartedAt = .now
            return true
        }
        allDone = true
        return false
    }

    /// Fine del blocco: salvo i tempi e decido dove andare
    func endBlock(elapsedSeconds: Int, reason: BlockEnd) {
        recordStepTime()
        session?.focusedSeconds += elapsedSeconds
        session?.blocks += 1
        blocksDone += 1
        lastBlockMinutes = max(1, Int((Double(elapsedSeconds) / 60).rounded()))

        switch reason {
        case .timeUp:   phase = .pauseAlert
        case .breakNow: phase = .breakTime
        case .stop:     phase = .checkOut
        case .allDone:
            allDone = true
            phase = .checkOut
        }
    }

    /// Aggiunge il tempo passato al passo corrente (anche se non è finito:
    /// un passo può durare più blocchi, il tempo si somma)
    private func recordStepTime() {
        if let start = stepStartedAt, let step = currentStep {
            step.actualSeconds += Int(Date().timeIntervalSince(start))
        }
        stepStartedAt = nil
    }

    // MARK: - Pausa

    /// L'utente salta la pausa dall'avviso
    func skipBreak() {
        phase = currentStep == nil ? .checkOut : .ready
    }

    /// Il timer della pausa è finito → "ORA SI TORNA A STUDIARE"
    func breakTimeUp() {
        phase = .studyAlert
    }

    /// Si torna a studiare. `real` = pausa fatta davvero senza telefono
    func backFromBreak(real: Bool) {
        if real { session?.realBreaks += 1 }
        phase = currentStep == nil ? .checkOut : .block
    }

    // MARK: - Fine

    func finishCheckOut(_ after: Mood) {
        session?.moodAfterRaw = after.rawValue
        phase = .summary
    }

    /// Chiusura con la X: se non è stato fatto niente, non salvo una sessione vuota
    func closeEarly() {
        recordStepTime()
        if let session, session.focusedSeconds == 0, session.stepsCompleted == 0 {
            context?.delete(session)
        }
        NotificationManager.shared.cancelAll()
        SoundPlayer.shared.stop()
    }

    // MARK: - 💭 Parcheggio dubbi

    func parkDoubt(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let context else { return }
        let doubt = Doubt(text: trimmed, topic: currentStep?.topic ?? exam.name, examName: exam.name)
        context.insert(doubt)
    }
}
