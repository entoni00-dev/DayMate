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
//  Lo riprendi con calma dopo: sul libro, con il prof o con un compagno.
//  Quando lo risolvi puoi scrivere in due righe cosa hai capito: diventa un appunto
//  da ripassare prima dell'esame.
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
    /// Cosa ho capito, scritto da me quando l'ho risolto (facoltativo)
    var answer: String?

    init(text: String, topic: String, examName: String) {
        self.text = text
        self.topic = topic
        self.examName = examName
        self.createdAt = .now
    }
}
