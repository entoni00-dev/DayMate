//
//  Countdown.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Un timer "robusto" riutilizzato sia per lo studio che per le pause.
//
//  🐛 Problema che ho incontrato: se uso un semplice contatore che fa -1 ogni secondo,
//  quando l'utente blocca il telefono iOS sospende l'app e il contatore si ferma.
//  Risultato: torni dopo 5 minuti e il timer segna ancora 4:30.
//
//  ✅ Soluzione: salvo la DATA DI FINE (endDate) e ogni volta calcolo
//  "quanto manca da adesso a endDate". Così, anche se l'app è stata sospesa,
//  al ritorno il tempo è giusto. Per avvisare l'utente a telefono bloccato
//  uso una notifica locale (vedi NotificationManager).
//
//  Uso @Observable (iOS 17): SwiftUI ridisegna da solo le viste che leggono `remaining`.
//

import Foundation
import Observation

@Observable
final class Countdown {

    /// Secondi rimanenti
    private(set) var remaining: TimeInterval = 0

    /// Durata totale impostata
    private(set) var total: TimeInterval = 1

    /// Se sta girando
    private(set) var isRunning = false

    /// Cosa fare quando arriva a zero. @ObservationIgnored perché non serve ridisegnare la UI.
    @ObservationIgnored var onFinish: (() -> Void)?

    @ObservationIgnored private var endDate: Date?
    @ObservationIgnored private var timer: Timer?

    /// Progresso 0 → 1 (per l'anello)
    var progress: Double {
        total > 0 ? 1 - remaining / total : 0
    }

    /// Secondi effettivamente trascorsi
    var elapsed: TimeInterval {
        total - remaining
    }

    /// Avvia il timer per un certo numero di secondi
    func start(seconds: TimeInterval) {
        total = seconds
        remaining = seconds
        endDate = Date().addingTimeInterval(seconds)
        isRunning = true

        timer?.invalidate()
        // Controllo ogni mezzo secondo: abbastanza preciso e leggero sulla batteria.
        let newTimer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common = il timer continua anche mentre l'utente scorre una lista
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    /// Ricalcola il tempo rimanente partendo dalla data di fine
    func tick() {
        guard let endDate, isRunning else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            stop()
            onFinish?()
        }
    }

    /// Ferma il timer (senza chiamare onFinish)
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Formattazione

extension TimeInterval {
    /// 125 secondi → "2:05"
    var mmss: String {
        let totalSeconds = Int(self.rounded(.up))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }
}
