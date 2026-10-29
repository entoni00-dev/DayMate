//
//  Doubt.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  💭 "Parcheggio dei dubbi".
//
//  Problema: mentre studi trovi qualcosa che non capisci → prendi il telefono per
//  cercarlo → 20 minuti dopo sei su Instagram. Oppure ti blocchi e smetti.
//  Soluzione: durante il blocco di studio scrivi il dubbio in 5 secondi e vai avanti.
//  Lo riprendi con calma dopo: con il Tutor AI (se disponibile), il prof o un compagno.
//
//  È anche il punto in cui l'AI si inserisce senza diventare una distrazione:
//  non chatti mentre studi, la usi a fine sessione.
//

import Foundation
import SwiftData

@Model
final class Doubt {
    var text: String
    var topic: String
    var examName: String
    var createdAt: Date
    var isResolved: Bool = false
    /// Risposta del Tutor AI o appunto scritto dall'utente
    var answer: String?

    init(text: String, topic: String, examName: String) {
        self.text = text
        self.topic = topic
        self.examName = examName
        self.createdAt = .now
    }
}
