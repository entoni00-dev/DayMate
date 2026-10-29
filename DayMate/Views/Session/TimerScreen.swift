//
//  TimerScreen.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  L'impaginazione della schermata "Timer" di Sketch, condivisa da:
//   - riscaldamento (anteprima e in corso)
//   - blocco di studio (pronto e in corso)
//   - pausa in corso
//
//     Math - step 3 of 6          ◐  ← cerchi decorativi
//     Read Ch. 2
//     Just the first page
//         ( anello + bradipo )
//             20:00
//     [ Start ]  [ Have a break ]
//

import SwiftUI

// 📌 Nota per me: <Accessory: View, Buttons: View> sono due "segnaposto" (si chiamano generics).
// Vuol dire: "qui dentro ci metterò delle viste, ma decido quali quando uso TimerScreen".
// Così ogni schermata del timer passa i SUOI bottoni, ma l'impaginazione è scritta una volta sola.
struct TimerScreen<Accessory: View, Buttons: View>: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    /// Riempimento dell'anello 0…1
    let progress: Double
    let active: Bool
    let pose: SlothPose
    let time: String
    var caption: String? = nil
    // @ViewBuilder mi permette di passare più viste una sotto l'altra dentro { },
    // proprio come faccio dentro un VStack
    @ViewBuilder var accessory: () -> Accessory   // cosa va sotto il tempo (es. il consiglio del passo)
    @ViewBuilder var buttons: () -> Buttons       // i bottoni in fondo

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(spacing: 18) {
                ScreenHeader(eyebrow: eyebrow, title: title, subtitle: subtitle)
                    .padding(.trailing, 70)   // non sovrapporre il "mezzo sole"

                SlothRing(progress: progress, active: active, pose: pose)
                    .frame(maxWidth: 290)
                    .padding(.top, 6)

                VStack(spacing: 2) {
                    Text(time)
                        .font(.system(size: 60, weight: .semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundStyle(.black)
                    if let caption {
                        Text(caption)
                            .font(.subheadline)
                            .foregroundStyle(Theme.mute)
                            .multilineTextAlignment(.center)
                    }
                }

                accessory()

                VStack(spacing: 12) {
                    buttons()
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background {
            DecoCircles(showSideCircle: true)
                .ignoresSafeArea()
        }
    }
}

// MARK: - "How to do it well" (il consiglio del passo)

struct StepTipView: View {
    let step: StudyStep
    var startExpanded = false

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                withAnimation(.snappy) { expanded.toggle() }
            } label: {
                HStack {
                    Label(tr("How to do it well", "Come farlo bene"), systemImage: "lightbulb.fill")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .foregroundStyle(Theme.rust)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Text(step.kind.tip)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        // .onAppear viene chiamato quando la schermata compare
        .onAppear { expanded = startExpanded }
    }
}
