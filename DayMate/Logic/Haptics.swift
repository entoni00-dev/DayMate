//
//  Haptics.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Piccole vibrazioni di feedback. Sono un dettaglio, ma fanno sentire
//  "fisico" il completamento di un passo: una mini-ricompensa.
//

import UIKit

enum Haptics {
    /// Vibrazione di successo (passo completato, timer finito)
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Tocco leggero (selezione)
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// "Sveglia": tre vibrazioni forti di fila, per gli avvisi pausa/studio
    static func alarm() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        for index in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.25) {
                generator.impactOccurred()
            }
        }
    }
}
