//
//  ChoiceView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Dopo il riscaldamento: "continuo, pausa o mi fermo?" — SENZA SENSI DI COLPA.
//
//  Scelta di design importante: "Mi fermo qui" è un'opzione legittima, non nascosta
//  e senza "sei sicuro?". Se fermarsi è punito, la prossima volta non inizi proprio
//  (per paura di non riuscire a smettere).
//

import SwiftUI

struct ChoiceView: View {
    let elapsedSeconds: Int
    let nextBlockMinutes: Int
    var onContinue: () -> Void
    var onBreak: () -> Void
    var onStop: () -> Void

    /// "2 minuti e 30 secondi" — formattato nella lingua dell'app
    private var elapsedText: String {
        Duration.seconds(elapsedSeconds)
            .formatted(.units(allowed: [.minutes, .seconds], width: .wide).locale(L10n.locale))
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            GlowRings(size: 240) {
                BlobView(pose: .cheer)
            }

            Text(tr("You did it: you started.", "Ce l'hai fatta: hai iniziato."))
                .font(.dmTitle)
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)

            Text(tr("Done in \(elapsedText). The hardest part is behind you. Now you choose, no guilt.",
                    "Fatto in \(elapsedText). La parte più difficile è passata. Ora scegli tu, senza sensi di colpa."))
                .font(.callout)
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            Button(tr("Keep going · \(nextBlockMinutes) min", "Continuo · \(nextBlockMinutes) min"), action: onContinue)
                .buttonStyle(PrimaryButtonStyle())

            Button(tr("First a real break", "Prima una pausa vera"), action: onBreak)
                .buttonStyle(QuietButtonStyle(color: Theme.lightMain))

            Button(tr("I'll stop here for today", "Mi fermo qui per oggi"), action: onStop)
                .buttonStyle(QuietButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    ChoiceView(elapsedSeconds: 130, nextBlockMinutes: 5, onContinue: {}, onBreak: {}, onStop: {})
        .background(Theme.background)
}
