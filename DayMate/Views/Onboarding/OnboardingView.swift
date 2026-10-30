//
//  OnboardingView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La Home, cioè la schermata iniziale (00 Start di Sketch), prima sezione della barra in basso:
//
//            ◯ ◯ (Blob) ◯ ◯
//              DayMate
//       One tiny step at a time
//
//   [📖 Study · start a tiny step ]    ← viola: è la scelta consigliata
//   [📅 Plan my day               ]
//   ─────────────────────────────────
//    🏠 Home · (sezioni della modalità) · ⚙️ Impostazioni
//
//  Qui si sceglie come usare l'app (come entrare "da utente" o "da titolare").
//  È la prima cosa che vedi OGNI volta che apri l'app: la domanda "cosa vuoi fare oggi?"
//  è voluta, perché un giorno studi e un altro organizzi la giornata.
//  Study e Plan si aprono "sopra" la Home: con "‹ Home" (o lo swipe) si torna qui.
//

import SwiftUI

struct OnboardingView: View {
    /// La modalità usata l'ultima volta (ha un piccolo ✓, così sai quale barra vedi sotto)
    var currentMode: AppMode? = nil
    /// Chiamata quando l'utente sceglie, con la modalità scelta
    var onFinish: (AppMode) -> Void

    // ♿️ @ScaledMetric: un numero che cresce insieme alla dimensione del testo scelta
    // dall'utente (Impostazioni → Schermo → Dimensioni testo). 38 è la misura di Sketch.
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 38
    // La dimensione del testo scelta dall'utente: se è enorme, rimpicciolisco gli anelli
    // così i bottoni restano sullo schermo
    @Environment(\.dynamicTypeSize) private var typeSize

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

            // 270 invece dei 300 di Sketch: sotto adesso c'è anche la barra delle sezioni
            GlowRings(size: typeSize.isAccessibilitySize ? 160 : 270, strongOuterRing: true) {
                BlobView(pose: .hello)
            }

            VStack(spacing: 8) {
                Text("DayMate")
                    .font(.system(size: titleSize, weight: .bold))
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
                        ModeRowLabel(mode: mode, isCurrent: mode == currentMode)
                    }
                    // "Study" è sempre viola (la scelta principale, come in Sketch);
                    // "Plan my day" diventa viola appena lo tocchi
                    .buttonStyle(ChoiceButtonStyle(isSelected: mode == .study))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

/// Una riga della Home: icona, titolo, sottotitolo (e ✓ se è la modalità in uso).
/// Quando la riga è viola (isLit) i testi diventano scuri, come "Study" in Sketch.
private struct ModeRowLabel: View {
    let mode: AppMode
    let isCurrent: Bool
    // lo legge da ChoiceButtonStyle: true = sono viola
    @Environment(\.isLit) private var isLit

    var body: some View {
        HStack(spacing: 16) {
            IconTile(systemName: mode.icon, inverted: isLit)
            VStack(alignment: .leading, spacing: 1) {
                Text(mode.choiceTitle)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(isLit ? Theme.background : Theme.text)
                Text(mode.startSubtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isLit ? Theme.background : Theme.secondary)
            }
            Spacer()
            // ✓ sulla modalità in uso (quella delle sezioni nella barra qui sotto)
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isLit ? Theme.background : Theme.accent)
                    .accessibilityLabel(tr("In use", "In uso"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    OnboardingView { _ in }
}
