//
//  StudyStep.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Un passo di studio: un'azione concreta con una durata stimata.
//  Es. "Leggi pagine 4–6 di «Limiti»" — 15 minuti.
//
//  🔄 Versione 2:
//   - `kindRaw`: il tipo di passo (lettura, richiamo, esercizio...) → decide icona e consiglio
//   - `actualSeconds`: quanto ci hai messo DAVVERO → l'app impara il tuo ritmo
//     e corregge le stime (vedi Exam.speedFactor)
//

import Foundation
import SwiftData

@Model
final class StudyStep {
    /// Testo dell'azione da fare
    var title: String

    /// Argomento di appartenenza (es. "Derivate")
    var topic: String

    /// Durata STIMATA in minuti
    var minutes: Int

    /// Posizione nel piano: SwiftData non conserva l'ordine degli array, quindi lo salvo io
    var order: Int

    /// Completato o no
    var isDone: Bool = false

    /// Quando è stato completato
    var completedAt: Date?

    /// Tipo di passo (StepKind), salvato come String
    var kindRaw: String = "read"   // = StepKind.read.rawValue (letterale: più sicuro per la migrazione)

    /// Secondi effettivamente passati su questo passo (sommati tra più blocchi)
    var actualSeconds: Int = 0

    /// L'esame a cui appartiene
    var exam: Exam?

    init(title: String, topic: String, minutes: Int, order: Int, kind: StepKind) {
        self.title = title
        self.topic = topic
        self.minutes = minutes
        self.order = order
        self.kindRaw = kind.rawValue
    }

    var kind: StepKind {
        StepKind(rawValue: kindRaw) ?? .read
    }
}
