//
//  StatTile.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Piccola card con un numero grande e un'etichetta (usata in Progressi e nel riepilogo).
//

import SwiftUI

struct StatTile: View {
    /// Icona SF Symbol sopra il numero
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Theme.accent)
            Text(value)
                .font(.system(.title, weight: .bold))
                .foregroundStyle(Theme.text)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardBackground(radius: 18)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    HStack {
        StatTile(icon: "timer", value: "42", label: "minutes of focus")
        StatTile(icon: "checkmark.circle", value: "12", label: "steps done")
    }
    .padding()
    .background(Theme.background)
}
