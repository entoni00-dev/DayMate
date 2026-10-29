//
//  BreakActivity.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Le attività per le "pause vere", lontano dallo schermo.
//
//  Non è un @Model perché sono dati fissi scritti nel codice:
//  non c'è bisogno di salvarli nel database.
//  (Idea futura: permettere all'utente di aggiungere le sue pause preferite.)
//

import Foundation

struct BreakActivity: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let title: String
    let detail: String

    /// Le 4 di Sketch per prime, poi le altre. Tutte brevi, fattibili in casa o sotto casa
    /// e soprattutto senza telefono.
    /// (`var` e non `let`: così i testi seguono la lingua scelta nell'app)
    static var all: [BreakActivity] { [
        BreakActivity(emoji: "🚶", title: tr("Take a walk", "Fai due passi"),
                      detail: tr("Around the block. Your phone stays on the desk.",
                                 "Un giro dell'isolato. Il telefono resta sulla scrivania.")),
        BreakActivity(emoji: "☕️", title: tr("Have a coffee", "Prenditi un caffè"),
                      detail: tr("Make it slowly, or go down to the café. No screen.",
                                 "Preparalo con calma, o scendi al bar. Niente schermo.")),
        BreakActivity(emoji: "🗣️", title: tr("Talk with a friend", "Parla con qualcuno"),
                      detail: tr("A real chat with a flatmate or whoever is home.",
                                 "Due chiacchiere vere con un coinquilino o con chi è in casa.")),
        BreakActivity(emoji: "🧘", title: tr("Stretch your body", "Sgranchisciti"),
                      detail: tr("Neck, shoulders and back: your body has been still too long.",
                                 "Collo, spalle e schiena: il corpo sta fermo da troppo.")),
        BreakActivity(emoji: "🪟", title: tr("Get some air", "Prendi un po' d'aria"),
                      detail: tr("Open the window or step onto the balcony and breathe slowly.",
                                 "Apri la finestra o esci sul balcone e respira lentamente.")),
        BreakActivity(emoji: "💧", title: tr("Drink some water", "Bevi un po' d'acqua"),
                      detail: tr("Fill your bottle and drink a whole glass.",
                                 "Riempi la bottiglia e bevi un bicchiere intero.")),
        BreakActivity(emoji: "🌬️", title: tr("Breathe", "Respira"),
                      detail: tr("10 slow breaths: in for 4 seconds, out for 6.",
                                 "10 respiri lenti: inspira 4 secondi, espira 6.")),
        BreakActivity(emoji: "👀", title: tr("Look far away", "Guarda lontano"),
                      detail: tr("Stare at something far outside the window: your eyes will thank you.",
                                 "Fissa qualcosa di lontano fuori dalla finestra: gli occhi ringraziano.")),
        BreakActivity(emoji: "🤸", title: tr("Move", "Muoviti"),
                      detail: tr("10 squats or 20 jumping jacks. Get the blood flowing.",
                                 "10 squat o 20 saltelli. Riattiva la circolazione.")),
        BreakActivity(emoji: "🍎", title: tr("Have a snack", "Uno snack"),
                      detail: tr("Prepare something to eat, calmly, away from screens.",
                                 "Prepara qualcosa da mangiare, con calma, senza schermo.")),
        BreakActivity(emoji: "🧹", title: tr("Tidy up", "Riordina"),
                      detail: tr("Clear your desk: restarting from a tidy space helps.",
                                 "Sistema la scrivania: ripartire da uno spazio ordinato aiuta.")),
    ] }

    /// Le 4 di Sketch: proposte la prima volta
    static var defaults: [BreakActivity] { Array(all.prefix(4)) }

    /// 4 idee a caso (bottone "Other ideas"). Poche scelte = meno fatica decisionale.
    static func suggestions(count: Int = 4) -> [BreakActivity] {
        Array(all.shuffled().prefix(count))
    }
}
