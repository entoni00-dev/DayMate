//
//  PhaseAlertView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La "sveglia" a schermo intero, nello stile di Sketch:
//     ⏸️  "Time for a break!"  (fine blocco)   → bradipo col cappellino
//     ▶️  "Welcome back!"      (fine pausa)    → bradipo che saluta ("Break over" di Sketch)
//
//  Perché una schermata intera e non un semplice popup?
//  Il cambio di modalità deve essere INEQUIVOCABILE. Un banner piccolo si ignora
//  ("finisco solo questa pagina..." e la pausa salta, oppure la pausa diventa mezz'ora).
//  Schermata dedicata + suono dedicato = il cervello capisce subito cosa fare.
//

import SwiftUI

struct PhaseAlertView: View {

    enum Kind {
        case pause
        case study

        var eyebrow: String {
            switch self {
            case .pause: return tr("Block done", "Blocco finito")
            case .study: return tr("Break over", "Pausa finita")
            }
        }

        var title: String {
            switch self {
            case .pause: return tr("Time for a break!", "È tempo di una pausa!")
            case .study: return tr("Welcome back!", "Bentornato!")
            }
        }

        var pose: SlothPose {
            switch self {
            case .pause: return .hat
            case .study: return .waving
            }
        }

        var sound: AlarmSound {
            switch self {
            case .pause: return .pause
            case .study: return .study
            }
        }
    }

    /// Un bottone della sveglia
    struct Action: Identifiable {
        enum Style { case dark, honey, link }
        let id = UUID()
        let title: String
        let style: Style
        let action: () -> Void
    }

    let kind: Kind
    let message: String
    let actions: [Action]

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(eyebrow: kind.eyebrow, title: kind.title)
                .padding(.top, 70)
                .padding(.trailing, 60)

            SlothView(pose: kind.pose)
                .frame(maxWidth: 300, maxHeight: 330)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .padding(.vertical, 12)

            Text(message)
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 16)

            VStack(spacing: 12) {
                ForEach(actions) { item in
                    switch item.style {
                    case .dark, .honey:
                        Button(item.title) {
                            SoundPlayer.shared.stop()
                            item.action()
                        }
                        .buttonStyle(PillButtonStyle(variant: item.style == .dark ? .dark : .honey))
                    case .link:
                        Button(item.title) {
                            SoundPlayer.shared.stop()
                            item.action()
                        }
                        .buttonStyle(TextLinkStyle())
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Theme.paper
                DecoCircles()
            }
            .ignoresSafeArea()
        }
        // .onAppear viene chiamato quando la schermata compare
        .onAppear {
            // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
            Haptics.alarm()
            SoundPlayer.shared.play(kind.sound)
        }
        .onDisappear {
            SoundPlayer.shared.stop()
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview("Pausa") {
    PhaseAlertView(kind: .pause,
                   message: "You studied for 25 minutes. Now 5 minutes away from the screen.",
                   actions: [
                    .init(title: "Have a break (5 min)", style: .honey, action: {}),
                    .init(title: "Skip the break", style: .link, action: {}),
                   ])
}

#Preview("Studio") {
    PhaseAlertView(kind: .study,
                   message: "Next up: Read pp. 4–6 of «Limits»",
                   actions: [
                    .init(title: "Back to study!", style: .dark, action: {}),
                    .init(title: "Home", style: .honey, action: {}),
                   ])
}
