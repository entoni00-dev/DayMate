//
//  AppMode.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🔀 I due modi di usare DayMate, scelti UNA volta all'inizio
//  (un po' come entrare "da utente" o "da titolare" in altre app):
//
//   📚 study   → "Organizza lo studio": Esami · Dubbi · Coach · Progressi
//   🗓️ planner → "Fai un planner":      Giorno · Settimana · Scadenze
//
//  La scelta resta salvata. Si cambia da Impostazioni → Modalità (i dati non si perdono:
//  esami, dubbi e attività restano sul telefono e ricompaiono se torni indietro).
//

import SwiftUI

enum AppMode: String, CaseIterable, Identifiable {
    case study
    case planner

    var id: String { rawValue }

    /// Chiave in UserDefaults ("" = non ancora scelta)
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
            return tr("Exams split into tiny steps, study sessions with real breaks, doubts and a coach.",
                      "Esami divisi in piccoli passi, sessioni di studio con pause vere, dubbi e un coach.")
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
