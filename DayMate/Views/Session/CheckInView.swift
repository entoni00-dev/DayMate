//
//  CheckInView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "How do you feel? — Your next step adapts to you" (schermata 04 di Sketch).
//  Una lista con 4 righe: il Blob con la faccia giusta, il nome dell'umore e cosa farà l'app.
//  Basta un tocco: niente bottone "Avanti" (un passo in meno tra me e lo studio).
//
//  La riuso due volte:
//   - all'inizio (check-in)  → decide come parte la sessione
//   - alla fine  (check-out) → per confrontare l'umore prima/dopo
//

import SwiftUI

struct CheckInView: View {
    let title: String
    let subtitle: String
    /// true = alla fine della sessione: non mostro "cosa farà l'app" sotto ogni umore
    var isCheckOut = false
    var onSelect: (Mood) -> Void

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenTitle(title: title, subtitle: subtitle, large: false)

                // La lista: una card con 4 righe separate da una linea
                VStack(spacing: 0) {
                    ForEach(Mood.allCases) { mood in
                        Button {
                            Haptics.tap()
                            onSelect(mood)
                        } label: {
                            MoodRowLabel(mood: mood, showsSubtitle: !isCheckOut)
                        }
                        // al tocco la riga diventa viola e si ingrandisce un po'
                        .buttonStyle(ChoiceButtonStyle(cornerRadius: 16, restColor: .clear))

                        // la linea va solo TRA le righe, non dopo l'ultima
                        if mood != Mood.allCases.last {
                            RowDivider()
                        }
                    }
                }
                .cardBackground(radius: 18)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}

/// Una riga di "How do you feel?": Blob, umore, cosa farà l'app, freccia
private struct MoodRowLabel: View {
    let mood: Mood
    let showsSubtitle: Bool
    // lo legge da ChoiceButtonStyle: true = sono viola (il dito è sopra di me)
    @Environment(\.isLit) private var isLit

    var body: some View {
        HStack(spacing: 14) {
            // il Blob in un cerchio chiaro
            BlobView(pose: mood.pose)
                .padding(5)
                .frame(width: 44, height: 44)
                .background(Theme.lightMain.opacity(0.9), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(mood.title)
                    .font(.dmRowTitle)
                    .foregroundStyle(isLit ? Theme.background : Theme.text)
                if showsSubtitle {
                    Text(mood.subtitle)
                        .font(.footnote)
                        .foregroundStyle(isLit ? Theme.background : Theme.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isLit ? Theme.background : Theme.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())   // tutta la riga è toccabile
        .accessibilityElement(children: .combine)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    CheckInView(title: "How do you feel?", subtitle: "Your next step adapts to you") { _ in }
        .background(Theme.background)
}
