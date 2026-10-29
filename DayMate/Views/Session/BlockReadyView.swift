//
//  BlockReadyView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il "Timer" di Sketch PRIMA di premere Start:
//  anello grigio, il bradipo con il libro, la durata del blocco e il passo da cui partire.
//  Sapere in anticipo che "tra 15 minuti c'è la pausa" rende più facile iniziare.
//

import SwiftUI

struct BlockReadyView: View {
    let model: StudySessionModel
    var onStart: () -> Void
    var onBreak: () -> Void

    private var nextBreak: Int {
        StudyRhythm.breakMinutes(afterBlocks: model.blocksDone + 1)
    }

    var body: some View {
        TimerScreen(
            eyebrow: "\(model.exam.name) - " + tr("step \(model.stepNumber) of \(model.stepTotal)",
                                                  "passo \(model.stepNumber) di \(model.stepTotal)"),
            title: model.currentStep?.title ?? tr("Ready?", "Pronto?"),
            subtitle: model.currentStep.map { step in
                "\(step.kind.emoji) \(step.kind.label) · ≈ \(model.exam.estimatedMinutes(for: step)) min"
            },
            progress: 0,
            active: false,
            pose: .book,
            time: "\(model.nextBlockMinutes):00",
            caption: tr("then \(nextBreak) minutes of real break ☕️", "poi \(nextBreak) minuti di pausa vera ☕️")
        ) {
            VStack(spacing: 10) {
                if model.blocksDone == 0 {
                    Text(model.mood == .great
                         ? tr("A short first block: the next ones will be \(AppSettings.blockMinutes) minutes.",
                              "Si parte con un blocco breve: i successivi saranno da \(AppSettings.blockMinutes) minuti.")
                         : tr("Blocks get longer little by little, up to \(AppSettings.blockMinutes) minutes when you're ready.",
                              "I blocchi si allungano piano piano: quando sei pronto arrivi a \(AppSettings.blockMinutes) minuti."))
                        .font(.footnote)
                        .foregroundStyle(Theme.mute)
                        .multilineTextAlignment(.center)
                }
                if let step = model.currentStep {
                    StepTipView(step: step)
                }
            }
        } buttons: {
            Button(tr("Start", "Inizia"), action: onStart)
                .buttonStyle(PillButtonStyle(variant: .dark))
            Button(tr("Have a break", "Fai una pausa"), action: onBreak)
                .buttonStyle(PillButtonStyle(variant: .honey))
        }
    }
}
