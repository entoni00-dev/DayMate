//
//  DayMateApp.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Punto di ingresso dell'app.
//
//  📌 Nota per me (e per chi legge il codice):
//  Ho scelto SwiftUI + SwiftData perché:
//   1. È lo stack "moderno" che ci fanno usare in Foundation.
//   2. SwiftData salva TUTTO sul telefono (un database SQLite locale gestito da Apple),
//      quindi non mi serve nessun server: è proprio uno dei punti chiave dell'idea.
//
//  Requisiti: iOS 17+ (SwiftData e @Observable esistono da iOS 17).
//

import SwiftUI
import SwiftData
import TipKit

@main
struct DayMateApp: App {

    init() {
        // Accendo TipKit (i suggerimenti "💡" dentro l'app, vedi DayMateTips.swift).
        // .immediate = i suggerimenti compaiono subito, senza aspettare.
        // "try?" perché configure() può dare errore: in quel caso semplicemente niente suggerimenti.
        try? Tips.configure([.displayFrequency(.immediate)])
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        // Qui "registro" i modelli che SwiftData deve salvare.
        // Il container viene iniettato nell'environment, così ogni vista
        // può usare @Query (per leggere) e \.modelContext (per scrivere).
        .modelContainer(for: [Exam.self, StudyStep.self, StudySession.self,
                              PlannerTask.self, WaterLog.self])
        // PlannerTask e WaterLog sono i dati della modalità Planner (vedi PlannerItems.swift)
    }
}
