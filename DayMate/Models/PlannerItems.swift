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

    init(title: String, day: Date, isDeadline: Bool = false) {
        self.title = title
        self.isDeadline = isDeadline
        self.day = Calendar.current.startOfDay(for: day)
        self.createdAt = .now
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
