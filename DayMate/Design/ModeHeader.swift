//
//  ModeHeader.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  L'intestazione in cima alle schermate principali:
//
//   ‹ Home                                    (+)
//   Study
//   Thursday 29 October
//
//  "‹ Home" riporta alla Home (la scelta Study / Plan my day); il "+" compare solo
//  dove c'è qualcosa da aggiungere. Le sezioni stanno nella barra IN BASSO (vedi RootView).
//
//  Per la barra in basso c'è anche un piccolo aiuto: .dmTabBar() (in fondo al file).
//

import SwiftUI

struct ModeHeader: View {
    /// Se c'è, in alto a sinistra compare "‹ Home" e toccandolo si torna alla Home
    var onHome: (() -> Void)? = nil
    /// Il titolo grande (il nome della sezione aperta, es. "Today")
    let title: String
    var subtitle: String? = nil
    /// Testo per VoiceOver del "+" (nil = in questa sezione non c'è niente da aggiungere)
    var addLabel: String? = nil
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Riga 1: "‹ Home" a sinistra, il "+" a destra
            HStack(spacing: 10) {
                // if let: il link compare solo se mi hanno passato cosa fare
                if let onHome {
                    TopLink(title: "Home", showsChevron: true, action: onHome)
                }

                Spacer()

                // if let: il "+" compare solo se la sezione ha qualcosa da aggiungere
                if let addLabel {
                    AddCircleButton(accessibilityTitle: addLabel, action: onAdd)
                }
            }
            // stessa altezza anche quando il "+" non c'è, così il titolo non "salta"
            .frame(minHeight: 44)

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
    ModeHeader(onHome: {}, title: "Study", subtitle: Date.now.longDayText)
        .background(Theme.background)
}
