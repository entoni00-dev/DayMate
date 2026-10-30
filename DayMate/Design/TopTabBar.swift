//
//  TopTabBar.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La parte alta delle due modalità (Studio / Planner):
//
//   [Studio]                                 ⚙️  (+)
//   Today
//   Thursday 29 October
//   ( Oggi )  Dubbi   Coach   Progressi          ← TopTabBar
//
//  📌 Nota per me: la TabView di Apple mette le sezioni IN BASSO. Noi le volevamo
//  in alto, sotto il titolo, quindi me la sono costruita: è una fila di bottoni
//  (HStack) e quello scelto è viola.
//
//  Per non scrivere due barre uguali (una per Studio e una per Planner) la barra
//  riceve una lista di TabItem: ognuno ha un id, un titolo e un'icona SF Symbol.
//

import SwiftUI

/// Una sezione della barra in alto
struct TabItem: Identifiable {
    let id: String       // es. "today"
    let title: String    // es. "Oggi"
    let icon: String     // nome di un SF Symbol, es. "sun.max.fill"
}

/// La fila di sezioni
struct TopTabBar: View {
    let items: [TabItem]
    /// L'id della sezione aperta in questo momento
    let selectedID: String
    /// Cosa fare quando tocco una sezione (gli passo il suo id)
    var onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                Button {
                    Haptics.tap()
                    onSelect(item.id)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.icon)
                            .font(.system(size: 13, weight: .bold))
                            // iOS 17: l'icona fa un piccolo "rimbalzo" quando la scelgo
                            .symbolEffect(.bounce, value: item.id == selectedID)
                        Text(item.title)
                            .font(.footnote.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)    // se il nome è lungo si rimpicciolisce un po'
                    }
                    // la sezione scelta: testo scuro su viola; le altre: grigio-lilla
                    .foregroundStyle(item.id == selectedID ? Theme.background : Theme.secondary)
                    .frame(maxWidth: .infinity)          // tutte le sezioni larghe uguali
                    .frame(height: 36)
                    .background(item.id == selectedID ? Theme.main : Color.clear, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(item.id == selectedID ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.card, in: Capsule())
    }
}

/// L'intestazione fissa in cima a una modalità
struct SpaceHeader: View {
    let mode: AppMode
    /// Il titolo grande (il nome della sezione aperta, es. "Today")
    let title: String
    var subtitle: String? = nil
    let items: [TabItem]
    let selectedID: String
    var onSelect: (String) -> Void
    /// Testo per VoiceOver del "+" (nil = in questa sezione non c'è niente da aggiungere)
    var addLabel: String? = nil
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Riga 1: la modalità a sinistra, impostazioni e "+" a destra
            HStack(spacing: 10) {
                Label(mode.title, systemImage: mode.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.lightMain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.card, in: Capsule())

                Spacer()

                // L'ingranaggio porta alle Impostazioni (la destinazione è nella vista della modalità)
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 38, height: 38)
                        .background(Theme.card, in: Circle())
                }
                .accessibilityLabel(tr("Settings", "Impostazioni"))

                if let addLabel {
                    AddCircleButton(accessibilityTitle: addLabel, action: onAdd)
                }
            }

            // Riga 2: titolo grande e data
            ScreenTitle(title: title, subtitle: subtitle)

            // Riga 3: le sezioni
            TopTabBar(items: items, selectedID: selectedID, onSelect: onSelect)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .background(Theme.background)
    }
}
