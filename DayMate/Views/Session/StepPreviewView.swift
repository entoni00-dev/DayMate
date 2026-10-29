//
//  StepPreviewView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il riscaldamento PRIMA di far partire il timer (solo Stuck / Stressed).
//  Una sola azione, scritta in grande, con la durata ben visibile:
//  il cervello deve leggere "solo 2 minuti", non "studia Analisi".
//

import SwiftUI

struct StepPreviewView: View {
    let step: PlannedStep
    let mood: Mood
    var onStart: () -> Void
    var onShrink: () -> Void

    var body: some View {
        TimerScreen(
            eyebrow: tr("Warm-up · just \(step.minutes) min", "Riscaldamento · solo \(step.minutes) min"),
            title: step.text,
            progress: 0,
            active: false,
            pose: .book,
            time: "\(step.minutes):00"
        ) {
            SlothBubble(text: mood.encouragement)
        } buttons: {
            Button(tr("Start", "Inizia"), action: onStart)
                .buttonStyle(PillButtonStyle(variant: .dark))
            Button(tr("Give me another tiny step", "Proponimi un altro passo minuscolo"), action: onShrink)
                .buttonStyle(PillButtonStyle(variant: .honey))
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    StepPreviewView(step: PlannedStep(text: "Open the book at the right page", minutes: 2, step: nil),
                    mood: .stuck, onStart: {}, onShrink: {})
}
