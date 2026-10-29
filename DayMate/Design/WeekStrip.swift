//
//  WeekStrip.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La striscia della settimana di Sketch:   M  T (W) T  F  S  S
//                                            7  8  9  10 11 12 13
//  Il giorno scelto ha il contorno a capsula. Un puntino segna i giorni "speciali"
//  (es. il giorno di un esame). Scorri a destra/sinistra per cambiare settimana.
//

import SwiftUI

struct WeekStrip: View {
    // @Binding = un valore che appartiene alla vista "madre": lo leggo e lo cambio, ma non è mio
    @Binding var selected: Date
    /// Giorni da segnare con un puntino (qualsiasi ora: confronto solo il giorno)
    var marked: [Date] = []

    /// Settimana che parte dal lunedì, come in Sketch
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        calendar.locale = L10n.locale
        return calendar
    }

    private var days: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: selected) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                dayButton(day)
                    .frame(maxWidth: .infinity)
            }
        }
        .contentShape(Rectangle())
        // Swipe per cambiare settimana
        .gesture(
            // DragGesture = il dito che trascina
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -40 { move(weeks: 1) }
                    if value.translation.width > 40 { move(weeks: -1) }
                }
        )
    }

    private func dayButton(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selected)
        let isToday = calendar.isDateInToday(day)
        let isMarked = marked.contains { calendar.isDate($0, inSameDayAs: day) }

        return Button {
            Haptics.tap()
            // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
            withAnimation(.snappy) { selected = day }
        } label: {
            VStack(spacing: 5) {
                Text(day.formatted(.dateTime.weekday(.narrow).locale(L10n.locale)))
                    .font(.system(.subheadline, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(.subheadline, design: .serif, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? Theme.rust : Theme.mute)
                Circle()
                    .fill(isMarked ? Theme.rust : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 40, height: 66)
            .overlay {
                if isSelected {
                    Capsule().strokeBorder(Theme.ink, lineWidth: 1.5)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func move(weeks: Int) {
        if let date = calendar.date(byAdding: .day, value: 7 * weeks, to: selected) {
            Haptics.tap()
            withAnimation(.snappy) { selected = date }
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    WeekStrip(selected: .constant(Date()), marked: [Date().addingTimeInterval(86_400 * 2)])
        .padding()
}
