//
//  BreakActivity.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Le attività per le "pause vere", lontano dallo schermo ("PICK ONE" in Sketch).
//
//  Non è un @Model perché sono dati fissi scritti nel codice:
//  non c'è bisogno di salvarli nel database.
//  (Idea futura: permettere all'utente di aggiungere le sue pause preferite.)
//

import Foundation

struct BreakActivity: Identifiable, Hashable {
    let id = UUID()
    /// Icona SF Symbol (es. "figure.walk")
    let icon: String
    let title: String
    let detail: String

    /// Le 3 di Sketch per prime, poi le altre. Tutte brevi, fattibili in casa o sotto casa
    /// e soprattutto senza telefono.
    /// (`var` e non `let`: così i testi seguono la lingua scelta nell'app)
    static var all: [BreakActivity] { [
        BreakActivity(icon: "figure.walk", title: tr("Short walk", "Due passi"),
                      detail: tr("Go outside, 10 min", "Esci, 10 minuti")),
        BreakActivity(icon: "wind", title: tr("Stretch & breathe", "Stretching e respiro"),
                      detail: tr("4 easy moves", "4 movimenti facili")),
        BreakActivity(icon: "cup.and.saucer", title: tr("Snack & water", "Snack e acqua"),
                      detail: tr("Refill your bottle", "Riempi la borraccia")),
        BreakActivity(icon: "person.2", title: tr("Talk to someone", "Parla con qualcuno"),
                      detail: tr("A real chat, no screens", "Due chiacchiere vere, senza schermi")),
        BreakActivity(icon: "window.casement", title: tr("Fresh air", "Aria fresca"),
                      detail: tr("Open the window, breathe slowly", "Apri la finestra e respira piano")),
        BreakActivity(icon: "eye", title: tr("Look far away", "Guarda lontano"),
                      detail: tr("Rest your eyes for a minute", "Fai riposare gli occhi un minuto")),
        BreakActivity(icon: "figure.run", title: tr("Move a bit", "Muoviti un po'"),
                      detail: tr("10 squats or 20 jumping jacks", "10 squat o 20 saltelli")),
        BreakActivity(icon: "sparkles", title: tr("Tidy your desk", "Riordina la scrivania"),
                      detail: tr("Restart from a clean space", "Riparti da uno spazio pulito")),
    ] }

    /// Le 3 di Sketch: proposte la prima volta
    static var defaults: [BreakActivity] { Array(all.prefix(3)) }

    /// 3 idee a caso (bottone "Other ideas"). Poche scelte = meno fatica decisionale.
    static func suggestions(count: Int = 3) -> [BreakActivity] {
        Array(all.shuffled().prefix(count))
    }
}
