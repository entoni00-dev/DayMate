//
//  ModeChoiceView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  L'ultima schermata dell'introduzione: "Come vuoi usare DayMate?"
//  Da qui si entra in uno dei due modi dell'app (Studio o Planner).
//

import SwiftUI

struct ModeChoiceView: View {
    /// Chiamata quando l'utente preme "Entra": RootView salva la scelta e apre la modalità
    var onChoose: (AppMode) -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var selected: AppMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScreenHeader(eyebrow: tr("Last step", "Ultimo passo"),
                         title: tr("How do you want to use DayMate?", "Come vuoi usare DayMate?"),
                         subtitle: tr("You can change it later in Settings.",
                                      "Potrai cambiarlo dopo nelle Impostazioni."))
                .padding(.top, 20)

            ForEach(AppMode.allCases) { mode in
                Button {
                    Haptics.tap()
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation(.spring(response: 0.35)) { selected = mode }
                } label: {
                    ModeCard(mode: mode, isSelected: selected == mode)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)

            // Finché non scelgo niente il bottone dice "Scegli una modalità" ed è disattivato
            Button(selected.map { tr("Enter: \($0.title)", "Entra: \($0.title)") } ?? tr("Choose one", "Scegli una modalità")) {
                if let selected {
                    Haptics.success()
                    onChoose(selected)
                }
            }
            .buttonStyle(PillButtonStyle(variant: .dark))
            .disabled(selected == nil)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background {
            ZStack {
                Theme.paper
                DecoCircles(color: selected?.color ?? Theme.honey)
            }
            .ignoresSafeArea()
        }
    }
}

private struct ModeCard: View {
    let mode: AppMode
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label(mode.title.uppercased(), systemImage: mode.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                Text(mode.choiceTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                Text(mode.choiceSubtitle)
                    .font(.dmSerif)
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            SlothView(pose: mode.pose)
                .frame(width: 92, height: 118)
        }
        .padding(18)
        .background(mode.color, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(isSelected ? Theme.cocoa : .black.opacity(0.06), lineWidth: isSelected ? 3.5 : 1))
        .overlay(alignment: .topTrailing) {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.cocoa, .white)
                    .padding(12)
            }
        }
        .scaleEffect(isSelected ? 1.02 : 1)
        .shadow(color: mode.color.opacity(0.35), radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    ModeChoiceView { _ in }
}
