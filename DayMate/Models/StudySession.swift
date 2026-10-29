//
//  StudySession.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Una sessione = dal check-in fino a quando l'utente si ferma.
//
//  💡 Idea aggiunta: CHECK-OUT dell'umore.
//  Nel prompt originale c'era solo il check-in iniziale. Io salvo anche come ti senti
//  ALLA FINE. Così l'app può mostrarti (con i tuoi dati!) che dopo aver iniziato
//  spesso l'ansia scende. È una prova concreta, non una frase motivazionale generica.
//  In più è un modo onesto per capire se l'app funziona davvero.
//

import Foundation
import SwiftData

@Model
final class StudySession {
    /// Quando è iniziata
    var startedAt: Date

    /// Umore prima di iniziare.
    /// Lo salvo come String (rawValue dell'enum) perché è il modo più semplice e
    /// sicuro con SwiftData: gli enum "custom" a volte danno problemi nelle query.
    var moodBeforeRaw: String

    /// Umore alla fine (nil se l'utente ha chiuso senza fare il check-out)
    var moodAfterRaw: String?

    /// Secondi di studio effettivo (somma dei timer)
    var focusedSeconds: Int = 0

    /// Quanti passi "veri" ha completato in questa sessione
    var stepsCompleted: Int = 0

    /// Quante pause fatte davvero lontano dal telefono (auto-dichiarate)
    var realBreaks: Int = 0

    /// Quanti blocchi di studio sono stati fatti (serve per capire se si fanno pause)
    var blocks: Int = 0

    /// Esame di riferimento (può diventare nil se l'esame viene eliminato)
    var exam: Exam?

    init(moodBefore: Mood) {
        self.startedAt = .now
        self.moodBeforeRaw = moodBefore.rawValue
    }

    // MARK: - Comodità (non salvate)

    var moodBefore: Mood {
        Mood(rawValue: moodBeforeRaw) ?? .great
    }

    var moodAfter: Mood? {
        guard let raw = moodAfterRaw else { return nil }
        return Mood(rawValue: raw)
    }

    /// true se alla fine stava meglio, false se no, nil se non ha fatto il check-out
    var improved: Bool? {
        guard let after = moodAfter else { return nil }
        return after.level < moodBefore.level
    }
}
