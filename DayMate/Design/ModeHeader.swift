//
//  ModeHeader.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  L'intestazione in cima a ogni sezione delle due modalità:
//
//   [📖 Studio]                               (+)
//   Today
//   Thursday 29 October
//
//  Le sezioni (Oggi, Dubbi, Progressi…) adesso stanno nella barra IN BASSO:
//  è la TabView di Apple, quella che hanno quasi tutte le app per iPhone.
//  Qui sopra resta solo il titolo e il "+" per aggiungere qualcosa.
//
//  Per la barra in basso c'è anche un piccolo aiuto: .dmTabBar() (in fondo al file).
//

import SwiftUI

struct ModeHeader: View {
    let mode: AppMode
    /// Il titolo grande (il nome della sezione aperta, es. "Today")
    let title: String
    var subtitle: String? = nil
    /// Testo per VoiceOver del "+" (nil = in questa sezione non c'è niente da aggiungere)
    var addLabel: String? = nil
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Riga 1: la modalità a sinistra, il "+" a destra
            HStack(spacing: 10) {
                Label(mode.title, systemImage: mode.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.lightMain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.card, in: Capsule())

                Spacer()

                // if let: il "+" compare solo se la sezione ha qualcosa da aggiungere
                if let addLabel {
                    AddCircleButton(accessibilityTitle: addLabel, action: onAdd)
                }
            }
            // stessa altezza anche quando il "+" non c'è, così il titolo non "salta"
            .frame(height: 44)

            // Riga 2: titolo grande e data
            ScreenTitle(title: title, subtitle: subtitle)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .background(Theme.background)
    }
}

// MARK: - La barra in basso

extension View {
    /// Colora la barra delle sezioni in basso con i colori di Ube night.
    /// 📌 Nota per me: questo modificatore va messo sul CONTENUTO di ogni sezione
    /// (dentro la TabView), non sulla TabView stessa, altrimenti non ha effetto.
    func dmTabBar() -> some View {
        self
            .toolbarBackground(Theme.card, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    ModeHeader(mode: .study, title: "Today", subtitle: Date.now.longDayText,
               addLabel: "New exam")
        .background(Theme.background)
}
