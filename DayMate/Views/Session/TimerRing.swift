//
//  TimerRing.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il grande anello del timer (schermata 05 di Sketch):
//
//        ◯  ← cerchio esterno tenue
//       ◯   ← cerchio verde sottile
//      ( 3:42 )  ← disco scuro con l'arco verde che avanza
//

import SwiftUI

struct TimerRing: View {
    /// Quanto tempo è passato, da 0 a 1
    var progress: Double
    /// Il testo al centro, es. "3:42"
    var time: String
    var size: CGFloat = 280

    var body: some View {
        ZStack {
            // due cerchi decorativi, come nella schermata iniziale
            Circle().stroke(Theme.accent.opacity(0.18), lineWidth: 1.5)
            Circle().stroke(Theme.accent.opacity(0.45), lineWidth: 1.5)
                .padding(size * 0.085)

            // il disco scuro con l'arco verde
            ZStack {
                Circle().fill(Theme.card)
                Circle()
                    .trim(from: 0, to: max(0.001, min(1, progress)))
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))   // parte da "ore 12"
                    .padding(10)
                    .animation(.easeInOut(duration: 0.5), value: progress)

                Text(time)
                    .font(.system(size: 48, weight: .bold))
                    .monospacedDigit()                 // le cifre larghe uguali: il numero non "balla"
                    .contentTransition(.numericText()) // animazione dei numeri che cambiano
                    .foregroundStyle(Theme.text)
                    // il cerchio ha una misura fissa: se le cifre non ci stanno si rimpiccioliscono
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(size * 0.17)
        }
        .frame(width: size, height: size)
        // ♿️ VoiceOver legge "Tempo rimasto, 3:42" invece di un numero senza contesto
        .accessibilityElement()
        .accessibilityLabel(tr("Time left", "Tempo rimasto"))
        .accessibilityValue(time)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// I due bottoni tondi sotto il timer: ⏸ pausa e ✓ fatto
struct RoundTimerButton: View {
    let systemName: String
    /// true = il bottone verde (azione principale)
    var prominent = false
    let accessibilityTitle: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(prominent ? Theme.background : Theme.text)
                .frame(width: prominent ? 60 : 54, height: prominent ? 60 : 54)
                .background(prominent ? Theme.accent : Theme.card, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    VStack(spacing: 30) {
        TimerRing(progress: 0.3, time: "3:42")
        HStack(spacing: 24) {
            RoundTimerButton(systemName: "pause.fill", accessibilityTitle: "Pause") {}
            RoundTimerButton(systemName: "checkmark", prominent: true, accessibilityTitle: "Done") {}
        }
    }
    .padding()
    .background(Theme.background)
}
