//
//  CheckInView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Before studying… How do you feel?" — la schermata Mood di Sketch.
//  Quattro tessere miele con la faccia del bradipo; dopo la scelta compare il fumetto
//  ("Got it: I'll make the first step extra small") e si va avanti con "Next".
//
//  La riuso due volte:
//   - all'inizio (check-in)  → decide quanto piccolo sarà il primo passo
//   - alla fine  (check-out) → per confrontare l'umore prima/dopo
//

import SwiftUI

struct CheckInView: View {
    let eyebrow: String
    let title: String
    /// Testo del fumetto dopo la scelta (nil = uso l'incoraggiamento dell'umore)
    var bubbleText: ((Mood) -> String)? = nil
    var buttonTitle: String = tr("Next", "Avanti")
    var onSelect: (Mood) -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var selected: Mood?

    private let columns = [GridItem(.fixed(140), spacing: 18), GridItem(.fixed(140), spacing: 18)]

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(eyebrow: eyebrow, title: title)

            Spacer(minLength: 16)

            // LazyVGrid = una griglia (qui 2 colonne)
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(Mood.allCases) { mood in
                    Button {
                        Haptics.tap()
                        // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                        withAnimation(.spring(response: 0.35)) { selected = mood }
                    } label: {
                        MoodTile(mood: mood, isSelected: selected == mood)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 16)

            if let selected {
                SlothBubble(text: bubbleText?(selected) ?? selected.encouragement)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .id(selected)
                    .padding(.bottom, 14)
            }

            Button(buttonTitle) {
                if let selected { onSelect(selected) }
            }
            .buttonStyle(PillButtonStyle(variant: .dark))
            .disabled(selected == nil)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
}

/// Una tessera dell'umore
private struct MoodTile: View {
    let mood: Mood
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            SlothView(pose: mood.pose)
                .frame(width: 84, height: 84)
            Text(mood.title)
                .font(.system(.title3, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 140, height: 140)
        .background(Theme.honey, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(isSelected ? Theme.cocoa : .black.opacity(0.05), lineWidth: isSelected ? 3.5 : 1))
        .shadow(color: .black.opacity(isSelected ? 0.2 : 0.08), radius: isSelected ? 10 : 4, y: 3)
        .scaleEffect(isSelected ? 1.04 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    CheckInView(eyebrow: "Before studying…", title: "How do you feel?") { _ in }
}
