//
//  LiveActivityManager.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🏝️ Avvia, aggiorna e chiude la Live Activity del timer.
//
//  Perché esiste: l'idea di DayMate è "Phone down, one tiny step". Ma se il timer si vede
//  solo DENTRO l'app, per sapere quanto manca devo sbloccare il telefono… e lì arriva
//  la tentazione di aprire Instagram. Con la Live Activity il conto alla rovescia si vede
//  sulla schermata di blocco e nella Dynamic Island, senza sbloccare niente.
//
//  Come lo uso (dalle schermate del timer):
//   start(…)            → quando parte un blocco di studio o una pausa
//   pause(…) / resume(…) → quando premo ⏸ / ▶︎
//   changeStep(…)       → quando premo ✓ e passo al passo successivo
//   end(isBreak:)       → quando la schermata del timer sparisce
//
//  È un "singleton" (.shared) come NotificationManager: ce n'è uno solo in tutta l'app.
//

import Foundation
import ActivityKit

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    /// La Live Activity in corso (nil = nessuna)
    private var activity: Activity<StudyActivityAttributes>?
    /// L'ultimo stato mandato: mi serve per cambiare solo un pezzo (es. il titolo)
    private var state: StudyActivityAttributes.ContentState?
    /// Il testo in fondo "normale" (lo rimetto quando tolgo la pausa)
    private var normalFooter = ""

    /// Avvia una nuova Live Activity (se ce n'era già una, la chiude prima)
    func start(examName: String, title: String, subtitle: String, footer: String,
               isBreak: Bool, seconds: TimeInterval) {
        // L'utente può spegnere le Live Activity da Impostazioni: in quel caso non faccio niente
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        endNow()

        let now = Date()
        let newState = StudyActivityAttributes.ContentState(
            title: title, subtitle: subtitle, footer: footer, isBreak: isBreak,
            startDate: now, endDate: now.addingTimeInterval(seconds),
            pausedRemaining: nil, total: seconds)
        normalFooter = footer
        state = newState

        do {
            // staleDate: dopo questa data iOS sa che i dati sono "vecchi" (il timer è finito)
            activity = try Activity.request(
                attributes: StudyActivityAttributes(examName: examName),
                content: ActivityContent(state: newState, staleDate: newState.endDate),
                pushType: nil)          // nil = la aggiorno io dall'app, niente server
        } catch {
            // Se non parte (es. troppe Live Activity aperte) l'app funziona lo stesso
            print("Live Activity non avviata: \(error)")
        }
    }

    /// ⏸ Il tempo si ferma: mostro quanto mancava e la scritta "In pausa"
    func pause(remaining: TimeInterval, pausedText: String) {
        guard var newState = state else { return }
        newState.pausedRemaining = remaining
        newState.footer = pausedText
        send(newState)
    }

    /// ▶︎ Il tempo riparte: ricalcolo inizio e fine partendo da quanto manca
    func resume(remaining: TimeInterval) {
        guard var newState = state else { return }
        let now = Date()
        newState.startDate = now.addingTimeInterval(-(newState.total - remaining))
        newState.endDate = now.addingTimeInterval(remaining)
        newState.pausedRemaining = nil
        newState.footer = normalFooter
        send(newState)
    }

    /// ✓ Passo fatto: cambio solo titolo e sottotitolo, il tempo continua
    func changeStep(title: String, subtitle: String) {
        guard var newState = state else { return }
        newState.title = title
        newState.subtitle = subtitle
        send(newState)
    }

    /// Chiude la Live Activity, ma solo se è del tipo giusto.
    /// 🐛 Problema che ho incontrato: passando dal timer di studio alla pausa, SwiftUI
    /// può chiamare .onAppear della pausa PRIMA di .onDisappear dello studio. Senza questo
    /// controllo, lo studio che sparisce chiuderebbe la Live Activity appena aperta dalla pausa.
    func end(isBreak: Bool) {
        guard state?.isBreak == isBreak else { return }
        endNow()
    }

    // MARK: - Privato

    private func send(_ newState: StudyActivityAttributes.ContentState) {
        state = newState
        guard let activity else { return }
        // Task { await … }: l'aggiornamento è "asincrono", non blocca lo schermo
        Task {
            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }
    }

    private func endNow() {
        guard let old = activity else { return }
        activity = nil
        state = nil
        Task {
            // .immediate = sparisce subito dalla schermata di blocco
            await old.end(nil, dismissalPolicy: .immediate)
        }
    }
}
