//
//  Exam+Helpers.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Proprietà calcolate dell'esame (non salvate nel database).
//

import SwiftUI

extension Exam {

    // MARK: - Aspetto e tipo

    /// In Sketch tutti gli esami sono color miele (colorIndex resta nel modello per compatibilità)
    var color: Color { Theme.exam }

    var kind: ExamKind { ExamKind(rawValue: kindRaw) ?? .mixed }

    // MARK: - Passi

    /// I passi nell'ordine del piano: prima per FASE (studio → ripasso → simulazione),
    /// poi per `order`. Così anche un argomento aggiunto dopo finisce nella fase giusta
    /// e non dopo la simulazione.
    var sortedSteps: [StudyStep] {
        steps.sorted {
            let p0 = $0.kind.phase.rawValue, p1 = $1.kind.phase.rawValue
            return p0 == p1 ? $0.order < $1.order : p0 < p1
        }
    }

    var doneCount: Int { steps.filter { $0.isDone }.count }
    var remainingCount: Int { steps.count - doneCount }

    var progress: Double {
        steps.isEmpty ? 0 : Double(doneCount) / Double(steps.count)
    }

    /// Il primo passo non ancora fatto
    var nextStep: StudyStep? {
        sortedSteps.first { !$0.isDone }
    }

    /// Passi di una fase
    func phaseSteps(_ phase: StudyPhase) -> [StudyStep] {
        sortedSteps.filter { $0.kind.phase == phase }
    }

    /// Argomenti della fase di studio, nell'ordine di inserimento e senza duplicati
    var topics: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for step in phaseSteps(.learn) where !seen.contains(step.topic) {
            seen.insert(step.topic)
            result.append(step.topic)
        }
        return result
    }

    /// Passi di studio di un singolo argomento
    func topicSteps(_ topic: String) -> [StudyStep] {
        phaseSteps(.learn).filter { $0.topic == topic }
    }

    // MARK: - ⏱️ Calibrazione: quanto sei veloce DAVVERO?
    //
    // Le stime iniziali (minuti per pagina) sono uguali per tutti, ma ognuno studia
    // a una velocità diversa. Ogni volta che completi un passo, salvo quanto ci hai
    // messo davvero (actualSeconds). Confrontando tempo reale e tempo stimato ottengo
    // un fattore: 0.8 = sei più veloce del 20%, 1.3 = ti serve il 30% in più.
    // Lo applico a tutte le stime future → i tempi diventano "tuoi".

    /// Passi completati con un tempo misurato affidabile (almeno 1 minuto)
    var measuredSteps: [StudyStep] {
        steps.filter { $0.isDone && $0.actualSeconds >= 60 }
    }

    /// Fattore di velocità personale (1 = come previsto). Servono almeno 3 misure;
    /// lo limito tra 0.5 e 2 così un singolo passo "strano" non sballa tutto.
    var speedFactor: Double {
        let measured = measuredSteps
        guard measured.count >= 3 else { return 1 }
        let actual = Double(measured.reduce(0) { $0 + $1.actualSeconds })
        let estimated = Double(measured.reduce(0) { $0 + $1.minutes * 60 })
        guard estimated > 0 else { return 1 }
        return min(max(actual / estimated, 0.5), 2.0)
    }

    /// Stima personalizzata di un passo, in minuti.
    /// `factor` si può passare già calcolato quando stimo tanti passi di fila
    /// (calcolare speedFactor ogni volta sarebbe uno spreco).
    func estimatedMinutes(for step: StudyStep, factor: Double? = nil) -> Int {
        max(1, Int((Double(step.minutes) * (factor ?? speedFactor)).rounded()))
    }

    /// Minuti (personalizzati) ancora da fare
    var remainingMinutes: Int {
        let factor = speedFactor
        return steps.filter { !$0.isDone }.reduce(0) { $0 + estimatedMinutes(for: $1, factor: factor) }
    }

    // MARK: - Tempo

    /// Giorni che mancano all'esame (0 = oggi, negativo = già passato).
    var daysLeft: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let examDay = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: examDay).day ?? 0
    }

    var isPast: Bool { daysLeft < 0 }

    /// Testo lungo: "In 9 days" / "Tra 9 giorni"
    var countdownText: String {
        switch daysLeft {
        case ..<0: return tr("Exam passed", "Esame passato")
        case 0:    return tr("It's today! Good luck 🍀", "È oggi! In bocca al lupo 🍀")
        case 1:    return tr("Tomorrow", "Domani")
        default:   return tr("In \(daysLeft) days", "Tra \(daysLeft) giorni")
        }
    }

    /// Testo corto per la pillola di Sketch: "in 9 days"
    var countdownPill: String {
        switch daysLeft {
        case ..<0: return tr("passed", "passato")
        case 0:    return tr("today!", "oggi!")
        case 1:    return tr("tomorrow", "domani")
        default:   return tr("in \(daysLeft) days", "tra \(daysLeft) giorni")
        }
    }

    /// "3 of 6 steps done"
    var stepsDoneText: String {
        tr("\(doneCount) of \(steps.count) steps done", "\(doneCount) passi su \(steps.count) fatti")
    }
}

// MARK: - Formattazione dei minuti

extension Int {
    /// 95 → "1 h 35 min", 40 → "40 min"
    var asDuration: String {
        let hours = self / 60
        let minutes = self % 60
        if hours == 0 { return "\(minutes) min" }
        if minutes == 0 { return "\(hours) h" }
        return "\(hours) h \(minutes) min"
    }
}
