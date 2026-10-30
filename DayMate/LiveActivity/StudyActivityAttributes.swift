//
//  StudyActivityAttributes.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  ⏱️ I DATI della Live Activity: il timer sulla schermata di blocco e nella Dynamic Island.
//
//  Una Live Activity è fatta da due pezzi che vivono in due posti diversi:
//   1. l'APP la avvia, la aggiorna e la chiude      → LiveActivityManager.swift
//   2. l'ESTENSIONE WIDGET la disegna                → WidgetCode/DayMateWidgetLiveActivity.swift
//  Questo file è il "contratto" tra i due: deve far parte di ENTRAMBI i target.
//  ⚠️ In Xcode: seleziona questo file → pannello a destra (File Inspector) →
//     Target Membership → spunta anche "DayMateWidgetExtension".
//
//  📌 Nota per me:
//   - gli Attributes sono le cose che NON cambiano (il nome dell'esame)
//   - il ContentState sono le cose che cambiano (passo, tempo, pausa…)
//  L'estensione non può usare tr("…", "…") (vive in un processo separato), quindi
//  i testi arrivano già tradotti dall'app.
//

import Foundation
import ActivityKit

struct StudyActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        /// Il testo grande, es. "Read Ch. 2" oppure "Short walk"
        var title: String
        /// La riga piccola sopra, es. "Math · step 3 of 6"
        var subtitle: String
        /// La riga in fondo, es. "Phone down, one tiny step." oppure "Paused"
        var footer: String
        /// true = è una pausa (icona della tazza), false = studio (icona del libro)
        var isBreak: Bool
        /// Quando è partito il timer e quando finirà: l'orologio lo fa scorrere iOS da solo,
        /// senza che l'app debba aggiornare la Live Activity ogni secondo
        var startDate: Date
        var endDate: Date
        /// Se il timer è in pausa (⏸): i secondi che mancavano. nil = sta andando
        var pausedRemaining: Double?
        /// La durata totale in secondi (serve per l'anello quando è in pausa)
        var total: Double
    }

    /// Il nome dell'esame: non cambia durante la Live Activity
    var examName: String
}
