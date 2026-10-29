//
//  GentleQuotes.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Una frase "gentile" al giorno nella Home.
//
//  Ho evitato le classiche frasi motivazionali aggressive ("no pain no gain"):
//  a chi è in ansia fanno sentire ancora più in colpa. Il tono è:
//  abbassare l'asticella, normalizzare la fatica, premiare l'inizio.
//

import Foundation

enum GentleQuotes {

    static var all: [String] {
        [
            tr("You don't have to finish. You just have to start.",
               "Non devi finire. Devi solo iniziare."),
            tr("Two minutes count more than zero minutes.",
               "Due minuti contano più di zero minuti."),
            tr("An open book is already half the work.",
               "Il libro aperto è già metà del lavoro."),
            tr("Scrolling doesn't make you lazy: starting scares you. That's different.",
               "Se scrolli non sei pigro: iniziare ti fa paura. È diverso."),
            tr("Stopping after one step isn't failing. It's having started.",
               "Fermarsi dopo un passo non è fallire. È aver iniziato."),
            tr("Today, one paragraph can be enough.",
               "Oggi può bastare un paragrafo."),
            tr("The best break is the one away from the screen.",
               "La pausa migliore è quella lontana dallo schermo."),
            tr("You don't need motivation to start: starting creates motivation.",
               "Non serve la motivazione per iniziare: è iniziare che crea la motivazione."),
            tr("A small step taken beats a perfect plan postponed.",
               "Un passo piccolo fatto vale più di un piano perfetto rimandato."),
            tr("Slow is fine. Slow still moves forward.",
               "Piano va bene. Piano si va avanti lo stesso."),
        ]
    }

    /// La frase di oggi: cambia ogni giorno ma resta uguale durante la giornata.
    static var today: String {
        let quotes = all
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return quotes[day % quotes.count]
    }
}
