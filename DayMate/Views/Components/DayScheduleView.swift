//
//  DayScheduleView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il programma della giornata disegnato come una barra:
//  ██████ studio  ░░ pausa  ██████ studio  ░░ pausa  ███ studio
//
//  Vedere a colpo d'occhio che "oggi sono 3 blocchi con 2 pause" e a che ora
//  finisci rende la giornata concreta e finita, non un muro infinito di studio.
//

import SwiftUI

struct DayScheduleView: View {
    let studyMinutes: Int
    var studyColor: Color = Theme.honey
    var pauseColor: Color = Theme.lilac

    private var slots: [StudyRhythm.Slot] {
        StudyRhythm.daySchedule(studyMinutes: studyMinutes)
    }

    private var totalMinutes: Int { StudyRhythm.totalMinutes(of: slots) }
    private var blocks: Int { slots.filter { $0.kind == .study }.count }
    private var pauses: [StudyRhythm.Slot] { slots.filter { $0.kind == .pause } }
    private var pauseMinutes: Int { pauses.reduce(0) { $0 + $1.minutes } }

    /// Se inizi adesso, a che ora finisci?
    private var endTime: String {
        Date.now.addingTimeInterval(TimeInterval(totalMinutes * 60))
            .formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(L10n.locale))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Barra proporzionale
            GeometryReader { geometry in
                let spacing: CGFloat = 3
                let available = geometry.size.width - spacing * CGFloat(max(slots.count - 1, 0))
                HStack(spacing: spacing) {
                    ForEach(slots) { slot in
                        Capsule()
                            .fill(slot.kind == .study ? studyColor : pauseColor)
                            .frame(width: max(4, available * CGFloat(slot.minutes) / CGFloat(max(totalMinutes, 1))))
                    }
                }
            }
            .frame(height: 14)

            // Legenda
            HStack(spacing: 14) {
                legend(color: studyColor, text: tr("\(blocks) blocks · \(studyMinutes.asDuration)",
                                                   "\(blocks) blocchi · \(studyMinutes.asDuration)"))
                if !pauses.isEmpty {
                    legend(color: pauseColor, text: tr("\(pauses.count) breaks · \(pauseMinutes) min",
                                                       "\(pauses.count) pause · \(pauseMinutes) min"))
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.mute)

            Text(tr("Start now and you'll finish around \(endTime)", "Se inizi ora finisci verso le \(endTime)"))
                .font(.caption)
                .foregroundStyle(Theme.mute)
        }
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    DayScheduleView(studyMinutes: 95)
        .padding()
}
