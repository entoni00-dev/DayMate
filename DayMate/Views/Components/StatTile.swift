//
//  StatTile.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Piccola card con un numero grande e un'etichetta (usata in Progress e nel riepilogo).
//

import SwiftUI

struct StatTile: View {
    let emoji: String
    let value: String
    let label: String
    var color: Color = Theme.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(emoji)
                .font(.title2)
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.mute)
                .lineLimit(2)
        }
        .dmCard(radius: 22, padding: 14)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    HStack {
        StatTile(emoji: "⏱️", value: "42", label: "minutes of focus")
        StatTile(emoji: "✅", value: "12", label: "steps done")
    }
    .padding()
}
