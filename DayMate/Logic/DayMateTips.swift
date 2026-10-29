//
//  DayMateTips.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  💡 I suggestioni con TipKit (novità di iOS 17).
//
//  TipKit è il framework di Apple per mostrare piccoli consigli su come usare l'app,
//  con lo stesso stile delle app di sistema. La cosa comoda è che si ricorda DA SOLO
//  quali consigli ho già visto e chiuso: non devo salvare niente io.
//
//  Come si usa:
//   1. creo una struct che segue il protocollo `Tip` (titolo, messaggio, icona)
//   2. la mostro con TipView(IlMioTip()) dove voglio
//   3. all'avvio dell'app chiamo Tips.configure() (vedi DayMateApp.swift)
//

import SwiftUI
import TipKit

/// Nella sezione Esami: ricorda che basta un passo piccolo
struct TinyStepTip: Tip {
    var title: Text {
        Text(tr("Start with one tiny step", "Inizia con un piccolo passo"))
    }
    var message: Text? {
        Text(tr("Tap \"Next tiny step\": even 2 minutes count. DayMate adapts the timer to how you feel.",
                "Tocca \"Prossimo piccolo passo\": anche 2 minuti contano. DayMate adatta il timer a come ti senti."))
    }
    var image: Image? {
        Image(systemName: "tortoise.fill")
    }
}

/// Nella sezione Dubbi: spiega a cosa servono
struct DoubtTip: Tip {
    var title: Text {
        Text(tr("Park your doubts", "Parcheggia i dubbi"))
    }
    var message: Text? {
        Text(tr("Don't understand something? Tap \"+ Doubt\", write it in 5 seconds and keep studying. You'll solve it later.",
                "Qualcosa non ti è chiaro? Tocca \"+ Dubbio\", scrivilo in 5 secondi e continua a studiare. Lo risolvi dopo."))
    }
    var image: Image? {
        Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
    }
}

/// Nel Planner: come si eliminano le attività
struct PlannerTip: Tip {
    var title: Text {
        Text(tr("Your day, in one card", "La tua giornata, in una card"))
    }
    var message: Text? {
        Text(tr("Tap a box to tick it, long-press a task to delete it. Your study steps appear here by themselves.",
                "Tocca una casella per spuntarla, tieni premuta un'attività per eliminarla. I passi di studio compaiono qui da soli."))
    }
    var image: Image? {
        Image(systemName: "checklist")
    }
}
