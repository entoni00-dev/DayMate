//
//  WeekStrip.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La settimana della schermata "Plan" di Sketch:
//
//   ┌──┐┌──┐┌──┐┏━━┓┌──┐┌──┐┌──┐
//   │M ││T ││W │┃T ┃│F ││S ││S │
//   │26││27││28│┃29┃│30││31││1 │      ← il giorno scelto è viola
//   └──┘└──┘└──┘┗━━┛└──┘└──┘└──┘
//
//  Un puntino verde segna i giorni "speciali" (es. il giorno di un esame).
//  Scorri a destra/sinistra per cambiare settimana.
//

import SwiftUI

struct WeekStrip: View {
    // @Binding = un valore che appartiene alla vista "madre": lo leggo e lo cambio, ma non è mio
    @Binding var selected: Date
    /// Giorni da segnare con un puntino
    var marked: [Date] = []

    /// La settimana parte dal lunedì, come in Sketch
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2   // 1 = domenica, 2 = lunedì
        return calendar
    }

    /// I 7 giorni della settimana del giorno scelto
    private var days: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: selected) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    var body: some View {
        HStack(spacing: 7) {
            ForEach(days, id: \.self) { day in
                dayBox(day)
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

    private func dayBox(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selected)
        let isMarked = marked.contains { calendar.isDate($0, inSameDayAs: day) }

        return Button {
            Haptics.tap()
            withAnimation(.snappy) { selected = day }
        } label: {
            VStack(spacing: 4) {
                // "M", "T", "W"… (in italiano "L", "M", "M"…)
                Text(day.formatted(.dateTime.weekday(.narrow).locale(L10n.locale)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? Theme.background : Theme.secondary)
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(isSelected ? Theme.background : Theme.text)
                Circle()
                    .fill(isMarked ? (isSelected ? Theme.background : Theme.accent) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? Theme.main : Theme.card,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .background(Theme.background)
}
