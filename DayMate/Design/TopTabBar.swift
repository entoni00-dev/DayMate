//
//  TopTabBar.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La barra in alto delle due modalità:
//
//   🦥 DayMate [Studio]                 [+ Esame]  ⚙️
//   Organizza lo studio
//   Esami
//   ┌──────────┬──────────┬──────────┬──────────┐
//   │  Esami   │  Dubbi   │  Coach   │ Progressi│   ← TopTabBar
//   └──────────┴──────────┴──────────┴──────────┘
//
//  📌 Nota per me: all'inizio volevo usare la TabView di Apple, ma quella mette le
//  sezioni IN BASSO. Qui le volevamo in alto, sotto il titolo, quindi me la sono
//  costruita: è solo una fila di bottoni (HStack) e quello scelto è colorato.
//
//  Per non scrivere due barre uguali (una per Studio e una per Planner) la barra
//  riceve una lista di TabItem: ognuno ha un id, un titolo e un'icona SF Symbol.
//

import SwiftUI

/// Una sezione della barra in alto
struct TabItem: Identifiable {
    let id: String       // es. "exams"
    let title: String    // es. "Esami"
    let icon: String     // nome di un SF Symbol, es. "books.vertical.fill"
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
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .semibold))
                            // iOS 17: l'icona fa un piccolo "rimbalzo" quando la scelgo
                            .symbolEffect(.bounce, value: item.id == selectedID)
                        Text(item.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)   // se il nome è lungo si rimpicciolisce un po'
                    }
                    // la sezione scelta ha testo bianco su sfondo scuro, le altre il contrario
                    .foregroundStyle(item.id == selectedID ? Color.white : Theme.ink.opacity(0.75))
                    .frame(maxWidth: .infinity)   // tutte le sezioni larghe uguali
                    .padding(.vertical, 8)
                    .background(item.id == selectedID ? Theme.cocoa : Color.clear,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(Rectangle())    // tutta l'area è toccabile, non solo il testo
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(item.id == selectedID ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.pillGray, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// L'intestazione fissa in cima a una modalità: logo, "+", ingranaggio, titolo e barra
struct SpaceHeader: View {
    let mode: AppMode
    /// Il titolo grande (il nome della sezione aperta)
    let title: String
    let items: [TabItem]
    let selectedID: String
    var onSelect: (String) -> Void
    /// Testo del bottone "+" (nil = in questa sezione non c'è niente da aggiungere)
    var addLabel: String? = nil
    var onAdd: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Riga 1: logo + modalità a sinistra, "+" e impostazioni a destra
            HStack(spacing: 8) {
                SlothView(pose: .head)
                    .frame(width: 32, height: 32)
                Text("DayMate")
                    .font(.system(.headline, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(mode.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(mode.color, in: Capsule())

                Spacer()

                if let addLabel {
                    Button {
                        Haptics.tap()
                        onAdd()
                    } label: {
                        Label(addLabel, systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Theme.cocoa, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                // L'ingranaggio porta alle Impostazioni (la destinazione è nella vista della modalità)
                NavigationLink(value: AppRoute.settings) {
                    Image(systemName: "gearshape.fill")
                        .font(.headline)
                        .foregroundStyle(Theme.mute)
                        .frame(width: 38, height: 38)
                        .background(Theme.pillGray, in: Circle())
                }
                .accessibilityLabel(tr("Settings", "Impostazioni"))
            }

            // Riga 2: "Organizza lo studio" + il nome della sezione
            ScreenHeader(eyebrow: mode.choiceTitle, title: title)

            // Riga 3: le sezioni
            TopTabBar(items: items, selectedID: selectedID, onSelect: onSelect)
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background(Theme.paper)
    }
}
