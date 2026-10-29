//
//  SessionSummaryView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Riepilogo di fine sessione + confronto dell'umore prima/dopo.
//
//  Il confronto è la parte importante: se l'utente VEDE (sui suoi dati)
//  che dopo aver iniziato l'ansia scende, la prossima volta che è bloccato
//  ha un motivo concreto per provarci. È una prova, non una promessa.
//

import SwiftUI

struct SessionSummaryView: View {
    let session: StudySession
    let allDone: Bool
    var onClose: () -> Void

    private var focusMinutes: Int {
        Int((Double(session.focusedSeconds) / 60).rounded())
    }

    /// Messaggio in base a come è cambiato l'umore
    private var moodMessage: String {
        guard let after = session.moodAfter else {
            return tr("You started. That was the hardest part.", "Hai iniziato. Era la parte più difficile.")
        }
        if after.level < session.moodBefore.level {
            return tr("Did you notice? After starting you feel better than before. Remember it next time you feel stuck.",
                      "Hai notato? Dopo aver iniziato ti senti meglio di prima. Ricordatelo la prossima volta che ti senti bloccato.")
        } else if after.level == session.moodBefore.level {
            return tr("Same mood, but in the meantime you did something real. That counts.",
                      "L'umore è lo stesso, ma intanto hai fatto qualcosa di concreto. Conta.")
        } else {
            return tr("Today was tough, and that's normal. You still started: tomorrow will be a little easier.",
                      "Oggi è stata dura, ed è normale. Hai comunque iniziato: domani sarà un po' più facile.")
        }
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(spacing: 20) {
                SlothView(pose: allDone ? .waving : .great)
                    .frame(height: 170)
                    .padding(.top, 30)

                ScreenHeader(eyebrow: allDone ? tr("All steps done!", "Tutti i passi fatti!")
                                              : tr("Session over", "Sessione conclusa"),
                             title: tr("Well done, slowly but surely", "Ben fatto, piano ma sicuro"),
                             alignment: .center)

                // Numeri della sessione
                HStack(spacing: 12) {
                    StatTile(emoji: "⏱️", value: "\(focusMinutes)", label: tr("minutes", "minuti"))
                    StatTile(emoji: "✅", value: "\(session.stepsCompleted)", label: tr("steps", "passi"))
                    StatTile(emoji: "🚶", value: "\(session.realBreaks)", label: tr("real breaks", "pause vere"))
                }

                // Confronto umore
                VStack(spacing: 14) {
                    HStack(spacing: 18) {
                        moodBadge(session.moodBefore, label: tr("Before", "Prima"))
                        Image(systemName: "arrow.right")
                            .font(.title2.bold())
                            .foregroundStyle(Theme.mute)
                        if let after = session.moodAfter {
                            moodBadge(after, label: tr("After", "Dopo"))
                        }
                    }
                    Text(moodMessage)
                        .font(.subheadline)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .dmCard(Theme.cream)

                Button(tr("Close", "Chiudi"), action: onClose)
                    .buttonStyle(PillButtonStyle(variant: .dark))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func moodBadge(_ mood: Mood, label: String) -> some View {
        VStack(spacing: 6) {
            SlothView(pose: mood.pose)
                .padding(8)
                .frame(width: 76, height: 76)
                .background(Theme.honey, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text("\(label) · \(mood.title)")
                .font(.caption.bold())
                .foregroundStyle(Theme.mute)
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    // Uso una sessione dal database di preview: creare un @Model "volante"
    // prima che esista un container può far crashare la preview.
    SessionSummaryView(session: PreviewData.sampleSession, allDone: false) {}
        .modelContainer(PreviewData.container)
}
