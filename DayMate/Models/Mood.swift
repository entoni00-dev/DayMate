//
//  Mood.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "How do you feel?" — i quattro stati della schermata Mood di Sketch.
//  La frase sotto ogni umore dice SUBITO cosa succederà, così l'utente si fida:
//
//   😊 Ready     → "Full step, 25 min"     blocco intero
//   😴 Tired     → "Shorter step, 10 min"  blocchi corti che crescono piano
//   😣 Stressed  → "Start with a break"    prima una pausa per respirare, poi si studia
//   🧱 Stuck     → "Easier step first"     un gesto minuscolo di 2 minuti ("apri il libro")
//
//  Regola del progetto: PIÙ SEI BLOCCATO, PIÙ IL PRIMO PASSO È PICCOLO.
//

import SwiftUI

enum Mood: String, CaseIterable, Identifiable {
    case ready
    case tired
    case stressed
    case stuck

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ready:    return tr("Ready", "Pronto")
        case .tired:    return tr("Tired", "Stanco")
        case .stressed: return tr("Stressed", "Stressato")
        case .stuck:    return tr("Stuck", "Bloccato")
        }
    }

    /// La riga grigia sotto il titolo: cosa farà l'app
    var subtitle: String {
        switch self {
        case .ready:    return tr("Full step, \(AppSettings.blockMinutes) min", "Passo intero, \(AppSettings.blockMinutes) min")
        case .tired:    return tr("Shorter step, 10 min", "Passo più corto, 10 min")
        case .stressed: return tr("Start with a break", "Si parte con una pausa")
        case .stuck:    return tr("Easier step first", "Prima un passo facilissimo")
        }
    }

    /// La faccia del Blob per questo umore
    var pose: BlobPose {
        switch self {
        case .ready:    return .ready
        case .tired:    return .tired
        case .stressed: return .stressed
        case .stuck:    return .stuck
        }
    }

    /// Emoji compatta (lista delle sessioni recenti)
    var emoji: String {
        switch self {
        case .ready:    return "😊"
        case .tired:    return "😴"
        case .stressed: return "😣"
        case .stuck:    return "🧱"
        }
    }

    /// Livello numerico per confrontare prima/dopo (più basso = meglio)
    var level: Int {
        switch self {
        case .ready:    return 0
        case .tired:    return 1
        case .stressed: return 2
        case .stuck:    return 2
        }
    }

    /// Durata del riscaldamento (solo "Stuck" ne ha uno)
    var firstTimerMinutes: Int {
        self == .stuck ? 2 : 0
    }
}
