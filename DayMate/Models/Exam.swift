//
//  Exam.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il modello principale: un esame da preparare.
//
//  📌 Come funziona @Model:
//  La macro @Model trasforma questa classe in qualcosa che SwiftData sa salvare.
//  Ogni proprietà "stored" (var name, var date, ...) diventa una colonna nel database.
//  Le proprietà calcolate invece NON vengono salvate: le ho messe in
//  Exam+Helpers.swift per tenere pulito il modello.
//
//  🔄 Versione 2: ho aggiunto `kindRaw` e `dailyMinutes`. Hanno un valore di default,
//  così SwiftData riesce a migrare da solo i dati della versione 1.
//

import Foundation
import SwiftData

@Model
final class Exam {
    /// Nome dell'esame, es. "Analisi 1"
    var name: String

    /// Data dell'esame (mi interessa solo il giorno, non l'ora)
    var date: Date

    /// Emoji scelta dall'utente
    var emoji: String

    /// Indice del colore nella palette di Theme (salvo un Int perché Color non è salvabile)
    var colorIndex: Int

    /// Quando l'ho creato
    var createdAt: Date

    /// Tipo di esame (teoria / esercizi / misto), salvato come String
    var kindRaw: String = "mixed"   // = ExamKind.mixed.rawValue (letterale: più sicuro per la migrazione)

    /// Quanti minuti al giorno l'utente PUÒ dedicare a questo esame.
    /// Serve al pianificatore per dire onestamente se il piano "ci sta" o no.
    var dailyMinutes: Int = 120

    /// I mini-passi. .cascade = se elimino l'esame, elimino anche i passi.
    @Relationship(deleteRule: .cascade, inverse: \StudyStep.exam)
    var steps: [StudyStep] = []

    /// Le sessioni. .nullify (e NON .cascade): se elimino l'esame, lo storico
    /// resta nelle statistiche ("hai iniziato 20 volte" resta vero!).
    @Relationship(deleteRule: .nullify, inverse: \StudySession.exam)
    var sessions: [StudySession] = []

    init(name: String, date: Date, emoji: String, colorIndex: Int, kind: ExamKind, dailyMinutes: Int) {
        self.name = name
        self.date = date
        self.emoji = emoji
        self.colorIndex = colorIndex
        self.createdAt = .now
        self.kindRaw = kind.rawValue
        self.dailyMinutes = dailyMinutes
    }
}
