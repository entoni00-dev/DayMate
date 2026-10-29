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

            SlothView(pose: .great)
                .frame(height: 170)

            ScreenHeader(eyebrow: tr("Warm-up done", "Riscaldamento fatto"),
                         title: tr("You did it: you started.", "Ce l'hai fatta: hai iniziato."),
                         subtitle: tr("Done in \(elapsedText). The hardest part is behind you. Now you choose, no guilt.",
                                      "Fatto in \(elapsedText). La parte più difficile è passata. Ora scegli tu, senza sensi di colpa."),
                         alignment: .center)

            Spacer(minLength: 0)

            Button {
                onContinue()
            } label: {
                Label(tr("Keep going: \(nextBlockMinutes) min block", "Continuo: blocco da \(nextBlockMinutes) min"),
                      systemImage: "arrow.right")
            }
            .buttonStyle(PillButtonStyle(variant: .dark))

            Button(tr("First a real break", "Prima una pausa vera"), action: onBreak)
                .buttonStyle(PillButtonStyle(variant: .honey))

            Button(tr("I'll stop here for today", "Mi fermo qui per oggi"), action: onStop)
                .buttonStyle(TextLinkStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    ChoiceView(elapsedSeconds: 130, nextBlockMinutes: 5, onContinue: {}, onBreak: {}, onStop: {})
}
