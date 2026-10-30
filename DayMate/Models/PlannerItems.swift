//
//  PlannerItems.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  I dati del "Planner" (nuova schermata di Sketch):
//   - PlannerTask → le cose da fare di una giornata (le caselline nella card lilla)
//   - WaterLog    → quanti bicchieri d'acqua hai bevuto in un giorno
//
//  Salvo il giorno come "inizio del giorno" (mezzanotte): così confrontare due date
//  è semplice e non dipende dall'ora in cui ho aggiunto la cosa.
//

import Foundation
import SwiftData

@Model
final class PlannerTask {
    var title: String
    /// Il giorno a cui appartiene (sempre a mezzanotte)
    var day: Date
    var isDone: Bool = false
    var createdAt: Date
    /// true = è una scadenza (consegna, esame, pagamento…): compare anche in "Scadenze"
    var isDeadline: Bool = false
    /// Il tipo ("Study", "Duty", "Free time") salvato come testo: vedi TaskKind
    var kindRaw: String = "duty"
    /// A che ora (nil = in qualsiasi momento della giornata)
    var time: Date?
    /// Quanto dura, in minuti
    var durationMinutes: Int = 30

    init(title: String, day: Date, kind: TaskKind = .duty, time: Date? = nil,
         durationMinutes: Int = 30, isDeadline: Bool = false) {
        self.title = title
        self.day = Calendar.current.startOfDay(for: day)
        self.createdAt = .now
        self.kindRaw = kind.rawValue
        self.time = time
        self.durationMinutes = durationMinutes
        self.isDeadline = isDeadline
    }

    var kind: TaskKind {
        TaskKind(rawValue: kindRaw) ?? .duty
    }

    /// "15:00" oppure "" se non ha un orario
    var timeText: String {
        guard let time else { return "" }
        return time.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(L10n.locale))
    }
}

/// I tre tipi di "Add to your day"
enum TaskKind: String, CaseIterable, Identifiable {
    case study, duty, free

    var id: String { rawValue }

    var title: String {
        switch self {
        case .study: return tr("Study", "Studio")
        case .duty:  return tr("Duty", "Impegno")
        case .free:  return tr("Free time", "Tempo libero")
        }
    }

    var icon: String {
        switch self {
        case .study: return "book"
        case .duty:  return "cup.and.saucer"
        case .free:  return "figure.walk"
        }
    }
}

@Model
final class WaterLog {
    /// Il giorno (sempre a mezzanotte)
    var day: Date
    var glasses: Int

    init(day: Date, glasses: Int = 0) {
        self.day = Calendar.current.startOfDay(for: day)
        self.glasses = glasses
    }
}
