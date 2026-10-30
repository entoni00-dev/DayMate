//
//  AppMode.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🔀 I due modi di usare DayMate, scelti nella Home OGNI volta che apri l'app
//  (un po' come entrare "da utente" o "da titolare" in altre app):
//
//   📚 study   → barra: Home · Oggi   · Progressi · Impostazioni
//   🗓️ planner → barra: Home · Giorno · Settimana · Scadenze  · Impostazioni
//
//  Salvo solo l'ULTIMA modalità scelta, per sapere quali sezioni mettere nella barra
//  mentre sei in Home. La domanda però arriva comunque: l'app parte sempre dalla Home.
//  Esami e attività restano sul telefono in tutte e due le modalità.
//

import SwiftUI

enum AppMode: String, CaseIterable, Identifiable {
    case study
    case planner

    var id: String { rawValue }

    /// Chiave in UserDefaults dell'ultima modalità scelta
    static let storageKey = "appMode"

    var title: String {
        switch self {
        case .study:   return tr("Study", "Studio")
        case .planner: return "Planner"
        }
    }

    /// Il titolo della card di scelta
    var choiceTitle: String {
        switch self {
        case .study:   return tr("Study", "Studia")
        case .planner: return tr("Plan my day", "Organizza la giornata")
        }
    }

    var choiceSubtitle: String {
        switch self {
        case .study:
            return tr("Exams split into tiny steps, study sessions with real breaks and your progress.",
                      "Esami divisi in piccoli passi, sessioni di studio con pause vere e i tuoi progressi.")
        case .planner:
            return tr("Your day and your week: tasks, water, deadlines. Simple and light.",
                      "La tua giornata e la tua settimana: attività, acqua, scadenze. Semplice e leggero.")
        }
    }

    /// La riga piccola sotto il titolo, nella schermata iniziale
    var startSubtitle: String {
        switch self {
        case .study:   return tr("start a tiny step", "inizia un piccolo passo")
        case .planner: return tr("tasks, water and deadlines", "attività, acqua e scadenze")
        }
    }

    var icon: String {
        switch self {
        case .study:   return "book"
        case .planner: return "calendar"
        }
    }
}
