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
        case .study:   return tr("Organise your study", "Organizza lo studio")
        case .planner: return tr("Make a planner", "Fai un planner")
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

    var color: Color {
        switch self {
        case .study:   return Theme.honey
        case .planner: return Theme.lilac
        }
    }

    var pose: SlothPose {
        switch self {
        case .study:   return .reading
        case .planner: return .calendar
        }
    }

    var icon: String {
        switch self {
        case .study:   return "books.vertical.fill"
        case .planner: return "calendar"
        }
    }
}
