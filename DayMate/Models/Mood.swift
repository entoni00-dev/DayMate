//
//  Mood.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  I quattro stati del check-in di Sketch: Great / Sleepy / Stuck / Stressed.
//
//  Regola del progetto: PIÙ SEI BLOCCATO, PIÙ IL PRIMO PASSO È PICCOLO.
//  Tutta la "personalizzazione" dell'app nasce da questo enum:
//
//   😊 Great     → nessun riscaldamento, primo blocco da 15'
//   😴 Sleepy    → nessun riscaldamento (serve energia, non un passo minuscolo),
//                  ma blocchi corti più a lungo: la pausa arriva prima
//   🧱 Stuck     → riscaldamento di 2' con un gesto fisico ("apri il libro")
//   😣 Stressed  → riscaldamento di 3': "leggi solo le prime righe"
//

import SwiftUI

enum Mood: String, CaseIterable, Identifiable {
    case great
    case sleepy
    case stuck
    case stressed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .great:    return tr("Great", "Alla grande")
        case .sleepy:   return tr("Sleepy", "Assonnato")
        case .stuck:    return tr("Stuck", "Bloccato")
        case .stressed: return tr("Stressed", "Stressato")
        }
    }

    /// La faccia del bradipo per questo umore
    var pose: SlothPose {
        switch self {
        case .great:    return .great
        case .sleepy:   return .sleepy
        case .stuck:    return .stuck
        case .stressed: return .stressed
        }
    }

    /// Emoji compatta (lista delle sessioni recenti)
    var emoji: String {
        switch self {
        case .great:    return "😊"
        case .sleepy:   return "😴"
        case .stuck:    return "🧱"
        case .stressed: return "😣"
        }
    }

    /// Livello numerico per confrontare prima/dopo (più basso = meglio)
    var level: Int {
        switch self {
        case .great:    return 0
        case .sleepy:   return 1
        case .stressed: return 2
        case .stuck:    return 2
        }
    }

    /// Durata del riscaldamento (0 = nessun riscaldamento)
    var firstTimerMinutes: Int {
        switch self {
        case .great, .sleepy: return 0
        case .stressed:       return 3
        case .stuck:          return 2
        }
    }

    /// Il fumetto del bradipo dopo la scelta ("Got it: I'll make the first step extra small").
    /// Tono: mai giudicante.
    var encouragement: String {
        switch self {
        case .great:
            return tr("Great! We start with a 15-minute block.",
                      "Ottimo! Partiamo con un blocco da 15 minuti.")
        case .sleepy:
            return tr("Got it: a glass of water, then short blocks.",
                      "Capito: un bicchiere d'acqua, poi blocchi corti.")
        case .stuck:
            return tr("Got it: I'll make the first step extra small.",
                      "Capito: il primo passo sarà piccolissimo.")
        case .stressed:
            return tr("Breathe. We start with just \(firstTimerMinutes) minutes.",
                      "Respira. Iniziamo con soli \(firstTimerMinutes) minuti.")
        }
    }
}
