//
//  TortoiseTrack.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La "pista" di Sketch: 🐢 ──●── · · · · 🐇
//  La fogliolina è il cursore. Due usi:
//   - SOLO LETTURA: quanto sei avanti con i passi di un esame (Exams)
//   - INTERATTIVA:  scegli il ritmo, dalla tartaruga (poco al giorno) alla lepre (tanto)
//                   (New Exam → tempo al giorno)
//

import SwiftUI

struct TortoiseTrack: View {
    /// Posizione del cursore, da 0 a 1
    var value: Double
    /// Quanti puntini disegnare sulla pista (es. il numero di passi). 0 = nessuno
    var dots: Int = 6
    /// Colore della parte "fatta" e delle icone
    var light = true
    /// Se non è nil la pista si può trascinare; riceve il nuovo valore 0…1
    var onChange: ((Double) -> Void)? = nil

    private var trackColor: Color { light ? .white.opacity(0.55) : Theme.stone }
    private var fillColor: Color { light ? .white : Theme.honey }
    private var iconColor: Color { light ? .white : Theme.mute.opacity(0.7) }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "tortoise.fill")
                .foregroundStyle(iconColor)
            // GeometryReader mi dice quanto spazio ho a disposizione (larghezza/altezza)
            GeometryReader { geometry in
                let width = geometry.size.width
                let knob: CGFloat = 38
                let x = CGFloat(min(max(value, 0), 1)) * (width - knob)

                ZStack(alignment: .leading) {
                    Capsule().fill(trackColor).frame(height: 6)
                    Capsule().fill(fillColor).frame(width: x + knob / 2, height: 6)

                    // Puntini (al massimo 12, altrimenti diventa una riga piena)
                    if dots > 0 {
                        HStack(spacing: 0) {
                            ForEach(0..<min(dots, 12), id: \.self) { _ in
                                Circle().fill(light ? Color.white : Theme.mute.opacity(0.35))
                                    .frame(width: 4, height: 4)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, knob / 2)
                        .offset(y: 12)
                    }

                    // Cursore con la foglia
                    Circle()
                        .fill(.white)
                        .overlay(Circle().strokeBorder(Theme.cocoa, lineWidth: 2.5))
                        .overlay(
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.leaf)
                        )
                        .frame(width: knob, height: knob)
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                        .offset(x: x)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    // DragGesture = il dito che trascina
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            guard let onChange else { return }
                            let newValue = (drag.location.x - knob / 2) / max(width - knob, 1)
                            onChange(Double(min(max(newValue, 0), 1)))
                        },
                    including: onChange == nil ? .none : .all
                )
            }
            .frame(height: 44)
            Image(systemName: "hare.fill")
                .foregroundStyle(iconColor)
        }
        .font(.title3)
        .accessibilityElement()
        .accessibilityValue("\(Int((value * 100).rounded()))%")
        .accessibilityAdjustableAction { direction in
            guard let onChange else { return }
            switch direction {
            case .increment: onChange(min(value + 1.0 / 6, 1))
            case .decrement: onChange(max(value - 1.0 / 6, 0))
            default: break
            }
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    VStack(spacing: 30) {
        TortoiseTrack(value: 0.5, dots: 6)
            .padding()
            .background(Theme.honey)
        TortoiseTrack(value: 0.1, dots: 8, light: false)
            .padding()
    }
    .padding()
}
