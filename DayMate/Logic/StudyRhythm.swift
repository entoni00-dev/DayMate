//
//  StudyRhythm.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Come si alternano STUDIO e PAUSA.
//
//  🪜 L'idea: "rampa" invece di Pomodoro fisso.
//  Il Pomodoro classico è 25 min studio + 5 min pausa, con una pausa lunga ogni 4 blocchi.
//  (Nota onesta: i 25 minuti sono una convenzione nata negli anni '80, non un numero magico
//  dimostrato dalla scienza. Ma è un buon punto di partenza, e si cambia nelle Impostazioni.)
//  Il problema è che 25 minuti sono TROPPI se sei bloccato. Quindi parto corto e allungo:
//
//     Stuck:     2' riscaldamento → 5' → 10' → 15' → 25' → 25' ...
//     Stressed:  3' riscaldamento → 10' → 15' → 20' → 25' ...
//     Sleepy:                       10' → 10' → 15' → 20' → 25' ...
//     Great:                        15' → 25' → 25' ...
//
//  Ogni blocco finito "dimostra" che ce la fai, e il successivo è solo un po' più lungo.
//

import Foundation

enum StudyRhythm {

    /// Lunghezze dei primi blocchi per ogni umore (poi si va a regime)
    static func ramp(for mood: Mood) -> [Int] {
        switch mood {
        case .stuck:    return [5, 10, 15]
        case .stressed: return [10, 15, 20]
        case .sleepy:   return [10, 10, 15, 20]   // con il sonno la pausa arriva prima, più a lungo
        case .great:    return [15]
        }
    }

    /// Durata del blocco numero `index` (0 = primo blocco dopo il riscaldamento)
    static func blockMinutes(index: Int, mood: Mood, target: Int = AppSettings.blockMinutes) -> Int {
        let steps = ramp(for: mood)
        return index < steps.count ? min(steps[index], target) : target
    }

    /// Pausa dopo `blocksDone` blocchi: lunga ogni 4 blocchi, altrimenti corta
    static func breakMinutes(afterBlocks blocksDone: Int,
                             short: Int = AppSettings.shortBreak,
                             long: Int = AppSettings.longBreak) -> Int {
        blocksDone > 0 && blocksDone % 4 == 0 ? long : short
    }

    // MARK: - Programma della giornata

    /// Un pezzo del programma: studio o pausa
    struct Slot: Identifiable {
        enum Kind { case study, pause }
        let id = UUID()
        let kind: Kind
        let minutes: Int
    }

    /// Trasforma "oggi devo studiare 70 minuti" in una sequenza concreta:
    /// 25' studio → 5' pausa → 25' studio → 5' pausa → 20' studio
    static func daySchedule(studyMinutes: Int,
                            target: Int = AppSettings.blockMinutes,
                            short: Int = AppSettings.shortBreak,
                            long: Int = AppSettings.longBreak) -> [Slot] {
        guard studyMinutes > 0, target > 0 else { return [] }

        var slots: [Slot] = []
        var remaining = studyMinutes
        var blocks = 0

        while remaining > 0 {
            var block = min(target, remaining)
            // Se avanzerebbe un "blocchetto" di meno di 5 minuti, lo unisco a questo
            if (1..<5).contains(remaining - block) { block = remaining }

            slots.append(Slot(kind: .study, minutes: block))
            remaining -= block
            blocks += 1

            if remaining > 0 {
                slots.append(Slot(kind: .pause, minutes: breakMinutes(afterBlocks: blocks, short: short, long: long)))
            }
        }
        return slots
    }

    /// Totale (studio + pause) di un programma
    static func totalMinutes(of slots: [Slot]) -> Int {
        slots.reduce(0) { $0 + $1.minutes }
    }
}
