//
//  OnboardingView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La schermata iniziale (00 Start di Sketch):
//
//            ◯ ◯ (Blob) ◯ ◯
//              DayMate
//       One tiny step at a time
//
//   [📖 Study · start a tiny step ]    ← viola: è la scelta consigliata
//   [📅 Plan my day               ]
//
//  Qui si sceglie come usare l'app (come entrare "da utente" o "da titolare").
//  Compare OGNI volta che apri l'app: la domanda "cosa vuoi fare oggi?" è voluta,
//  perché un giorno studi e un altro organizzi la giornata.
//  Da dentro l'app si torna qui con Impostazioni → "Cambia modalità".
//

import SwiftUI

struct OnboardingView: View {
    /// Chiamata quando l'utente sceglie, con la modalità scelta
    var onFinish: (AppMode) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // In alto a destra: la lingua (l'app parte in italiano)
            HStack {
                Spacer()
                LanguageToggle()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Spacer(minLength: 10)

            GlowRings(size: 300) {
                BlobView(pose: .hello)
            }

            VStack(spacing: 8) {
                Text("DayMate")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text(tr("One tiny step at a time", "Un piccolo passo alla volta"))
                    .font(.body)
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.top, 10)

            Spacer(minLength: 20)

            // Le due modalità
            VStack(spacing: 12) {
                ForEach(AppMode.allCases) { mode in
                    Button {
                        Haptics.success()
                        // Chiedo il permesso per le notifiche qui: servono per la sveglia
                        // di fine blocco e di fine pausa
                        NotificationManager.shared.requestPermission()
                        onFinish(mode)
                    } label: {
                        modeRow(mode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    /// Una riga: icona, titolo, sottotitolo. "Study" è viola (la scelta principale).
    private func modeRow(_ mode: AppMode) -> some View {
        let isMain = mode == .study

        return HStack(spacing: 16) {
            IconTile(systemName: mode.icon, inverted: isMain)
            VStack(alignment: .leading, spacing: 1) {
                Text(mode.choiceTitle)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(isMain ? Theme.background : Theme.text)
                Text(mode.startSubtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isMain ? Theme.background : Theme.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(isMain ? Theme.main : Theme.card,
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    OnboardingView { _ in }
}
