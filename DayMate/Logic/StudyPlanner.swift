//
//  StudyPlanner.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Distribuisce i passi rimanenti sui giorni che mancano all'esame.
//
//  🧠 Scelta importante: il piano NON è salvato, viene RICALCOLATO ogni volta.
//  Perché? Se ieri non hai studiato, un piano salvato ti mostrerebbe "3 passi in ritardo"
//  in rosso → senso di colpa → evitamento → scrolling (il circolo vizioso dell'idea!).
//  Ricalcolando, l'app redistribuisce il lavoro sui giorni rimasti e ti dice solo
//  cosa fare OGGI. Se il piano non ci sta più nel tempo che hai, te lo dice onestamente.
//
//  Dettaglio: i passi completati OGGI restano nel piano di oggi (spuntati).
//  Altrimenti, finito un passo, il piano si ricalcolerebbe "tirando dentro" quelli
//  di domani e non arriveresti mai a vedere "Oggi hai finito! 🎉".
//

import Foundation

/// Il piano di un singolo giorno
struct DayPlan: Identifiable {
    let date: Date
    let steps: [StudyStep]
    let minutes: Int          // minuti stimati totali del giorno
    let doneMinutes: Int      // minuti stimati dei passi già fatti

    var id: Date { date }

    var isToday: Bool { Calendar.current.isDateInToday(date) }
    var isComplete: Bool { !steps.isEmpty && steps.allSatisfy { $0.isDone } }
    var remainingMinutes: Int { max(0, minutes - doneMinutes) }
    var remainingSteps: Int { steps.filter { !$0.isDone }.count }
}

/// Il piano completo fino all'esame
struct StudyPlan {
    let days: [DayPlan]
    /// Minuti al giorno necessari per finire in tempo
    let neededPerDay: Int
    /// Minuti al giorno che l'utente ha detto di avere
    let availablePerDay: Int

    /// Il piano sta nel tempo disponibile? (tollero un 10% in più)
    var fits: Bool { Double(neededPerDay) <= Double(availablePerDay) * 1.1 }

    var today: DayPlan? { days.first { $0.isToday } }

    static let empty = StudyPlan(days: [], neededPerDay: 0, availablePerDay: 0)
}

enum StudyPlanner {

    static func plan(for exam: Exam, now: Date = .now) -> StudyPlan {
        let calendar = Calendar.current
        guard !exam.isPast else { return .empty }

        // Giorni di studio: da oggi al giorno PRIMA dell'esame.
        // Se l'esame è oggi o domani, resta comunque 1 giorno (oggi).
        let studyDays = max(exam.daysLeft, 1)
        let today = calendar.startOfDay(for: now)

        // Passi da pianificare: quelli da fare + quelli fatti oggi
        let pool = exam.sortedSteps.filter { step in
            if !step.isDone { return true }
            if let completed = step.completedAt { return calendar.isDate(completed, inSameDayAs: now) }
            return false
        }
        guard !pool.isEmpty else {
            return StudyPlan(days: [], neededPerDay: 0, availablePerDay: exam.dailyMinutes)
        }

        let factor = exam.speedFactor   // calcolato una volta sola
        let total = pool.reduce(0) { $0 + exam.estimatedMinutes(for: $1, factor: factor) }
        let perDay = Int((Double(total) / Double(studyDays)).rounded(.up))

        var days: [DayPlan] = []
        var index = 0

        for dayOffset in 0..<studyDays where index < pool.count {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let isLastDay = dayOffset == studyDays - 1

            var dayLoad = 0
            var doneLoad = 0
            var daySteps: [StudyStep] = []

            while index < pool.count {
                let step = pool[index]
                let minutes = exam.estimatedMinutes(for: step, factor: factor)
                // Prendo il passo se: è il primo del giorno, oppure è l'ultimo giorno,
                // oppure ne entra almeno metà nella quota giornaliera (evito giorni "a metà passo").
                let fits = dayLoad == 0 || isLastDay || dayLoad + minutes / 2 <= perDay
                guard fits else { break }

                daySteps.append(step)
                dayLoad += minutes
                if step.isDone { doneLoad += minutes }
                index += 1
            }

            days.append(DayPlan(date: date, steps: daySteps, minutes: dayLoad, doneMinutes: doneLoad))
        }

        return StudyPlan(days: days, neededPerDay: perDay, availablePerDay: exam.dailyMinutes)
    }
}
