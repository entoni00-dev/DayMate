//
//  AppMode.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🔀 I due modi di usare DayMate, scelti nella schermata iniziale OGNI volta che apri l'app
//  (un po' come entrare "da utente" o "da titolare" in altre app):
//
//   📚 study   → "Organizza lo studio": Oggi · Dubbi · Progressi · Impostazioni
//   🗓️ planner → "Fai un planner":      Giorno · Settimana · Scadenze · Impostazioni
//
//  La scelta NON viene salvata (vedi RootView). I dati invece sì: esami, dubbi e
//  attività restano sul telefono e ricompaiono quando torni in quella modalità.
//

import SwiftUI

enum AppMode: String, CaseIterable, Identifiable {
    case study
    case planner

    var id: String { rawValue }

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
            return tr("Exams split into tiny steps, study sessions with real breaks, doubts and progress.",
                      "Esami divisi in piccoli passi, sessioni di studio con pause vere, dubbi e progressi.")
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
