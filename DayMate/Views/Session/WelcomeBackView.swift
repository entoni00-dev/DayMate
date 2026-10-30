//
//  WelcomeBackView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Welcome back! — Ready for the next tiny step?" (schermata 07 di Sketch)
//
//  È la "sveglia" di fine pausa: suona un suono diverso da quello della pausa, così si
//  capisce cosa succede anche senza guardare lo schermo. Mostro SUBITO il prossimo
//  passo: niente "e adesso che faccio?".
//

import SwiftUI

struct WelcomeBackView: View {
    let exam: Exam
    let step: StudyStep?
    let stepNumber: Int
    /// Durata del prossimo blocco
    let minutes: Int
    var onStart: () -> Void
    /// "Not now": finisco qui
    var onNotNow: () -> Void
    /// Riparto, ma la pausa non era "vera" (ho usato il telefono)
    var onUsedPhone: () -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 0)

            GlowRings(size: 290) {
                BlobView(pose: .hello)
            }
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)

            Text(tr("Welcome back!", "Bentornato!"))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.text)
            Text(tr("Ready for the next tiny step?", "Pronto per il prossimo piccolo passo?"))
                .font(.callout)
                .foregroundStyle(Theme.secondary)

            // La card "NEXT TINY STEP"
            if let step {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tr("NEXT TINY STEP", "PROSSIMO PICCOLO PASSO"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.accent)
                        Text(step.title)
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(Theme.text)
                            .lineLimit(2)
                        Text("\(exam.name) · " + tr("step \(stepNumber) of \(exam.steps.count) · \(minutes) min",
                                                    "passo \(stepNumber) di \(exam.steps.count) · \(minutes) min"))
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondary)
                    }
                    Spacer()
                    ProgressRingView(progress: exam.progress, lineWidth: 4)
                        .frame(width: 40, height: 40)
                }
                .padding(20)
                .cardBackground(radius: 22)
                .padding(.top, 14)
            }

            Spacer(minLength: 0)

            Button(tr("Start step", "Inizia il passo")) {
                SoundPlayer.shared.stop()
                onStart()
            }
            .buttonStyle(PrimaryButtonStyle())

            HStack(spacing: 20) {
                Button(tr("Not now", "Non ora")) {
                    SoundPlayer.shared.stop()
                    onNotNow()
                }
                Button(tr("I used my phone 🙈", "Ho usato il telefono 🙈")) {
                    SoundPlayer.shared.stop()
                    onUsedPhone()
                }
            }
            .buttonStyle(QuietButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .onAppear {
            // withAnimation: il Blob "entra" con un piccolo rimbalzo
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
            Haptics.alarm()
            SoundPlayer.shared.play(.study)
        }
        .onDisappear {
            SoundPlayer.shared.stop()
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    WelcomeBackView(exam: PreviewData.sampleExam, step: PreviewData.sampleExam.nextStep,
                    stepNumber: 3, minutes: 10, onStart: {}, onNotNow: {}, onUsedPhone: {})
        .background(Theme.background)
        .modelContainer(PreviewData.container)
}
