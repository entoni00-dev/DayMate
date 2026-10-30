//
//  PlannerView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La giornata del Planner (schermata 08 "Plan" di Sketch):
//
//   [M][T][W][▉T▉][F][S][S]      ← la settimana, il giorno scelto è viola
//   STUDY                ✓ Math · step 2        09:30
//                        ○ Math · step 3        11:00
//   DUTIES & FREE TIME   ○ Lab report           15:00
//                        ○ Gym                  18:00
//   WATER                💧💧💧💧○○○○             4 / 8
//
//  Perché i passi d'esame anche qui? Così il Planner non è un'altra lista da tenere
//  aggiornata a mano: lo studio del giorno arriva da solo dal piano degli esami.
//

import SwiftUI
import SwiftData
import TipKit

struct PlannerView: View {
    /// Il giorno mostrato (condiviso con le altre sezioni del Planner)
    // @Binding = un valore che appartiene alla vista "madre": lo leggo e lo cambio, ma non è mio
    @Binding var day: Date

    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \PlannerTask.createdAt) private var allTasks: [PlannerTask]
    @Query private var waterLogs: [WaterLog]
    @Query(sort: \Exam.date) private var exams: [Exam]

    private var calendar: Calendar { .current }

    /// Le attività del giorno scelto, in ordine di orario (quelle senza orario in fondo)
    private var tasks: [PlannerTask] {
        allTasks.filter { calendar.isDate($0.day, inSameDayAs: day) }
            .sorted { ($0.time ?? .distantFuture) < ($1.time ?? .distantFuture) }
    }

    /// Le attività di tipo "Study" vanno nella sezione STUDY, le altre in DUTIES & FREE TIME
    private var studyTasks: [PlannerTask] { tasks.filter { $0.kind == .study } }
    private var otherTasks: [PlannerTask] { tasks.filter { $0.kind != .study } }

    /// I passi di studio previsti dal piano degli esami per il giorno scelto
    private var examSteps: [StudyStep] {
        exams.filter { !$0.isPast }.flatMap { exam -> [StudyStep] in
            let dayPlan = StudyPlanner.plan(for: exam).days.first { calendar.isDate($0.date, inSameDayAs: day) }
            return dayPlan?.steps ?? []
        }
    }

    private var waterLog: WaterLog? {
        waterLogs.first { calendar.isDate($0.day, inSameDayAs: day) }
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                WeekStrip(selected: $day, marked: exams.map(\.date))

                // 💡 Suggerimento di TipKit
                TipView(PlannerTip())
                    .tint(Theme.main)

                // STUDY
                SectionHeader(text: tr("Study", "Studio"))
                listCard {
                    ForEach(examSteps) { step in
                        row(done: step.isDone,
                            title: "\(step.exam?.name ?? "") · \(step.title)",
                            trailing: "\(step.minutes) min") {
                            step.isDone.toggle()
                            step.completedAt = step.isDone ? .now : nil
                        }
                        RowDivider()
                    }
                    ForEach(studyTasks) { task in
                        taskRow(task)
                        RowDivider()
                    }
                    emptyRow(tr("No study planned", "Niente studio in programma"),
                             visible: examSteps.isEmpty && studyTasks.isEmpty)
                }

                // DUTIES & FREE TIME
                SectionHeader(text: tr("Duties & free time", "Impegni e tempo libero"))
                listCard {
                    ForEach(otherTasks) { task in
                        taskRow(task)
                        RowDivider()
                    }
                    emptyRow(tr("Tap + to add something", "Tocca + per aggiungere qualcosa"),
                             visible: otherTasks.isEmpty)
                }

                // WATER
                SectionHeader(text: tr("Water", "Acqua"))
                waterRow
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Pezzi della lista

    /// Una card che contiene delle righe
    private func listCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .cardBackground(radius: 18)
    }

    /// Una riga: cerchio, titolo, testo a destra. Tocco = segno fatto.
    private func row(done: Bool, title: String, trailing: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
            withAnimation(.snappy) { action() }
        } label: {
            HStack(spacing: 14) {
                CheckCircle(state: done ? .done : .todo)
                    .frame(width: 40)
                Text(title)
                    .font(.system(.callout, weight: .medium))
                    .foregroundStyle(done ? Theme.secondary : Theme.text)
                    .lineLimit(1)
                Spacer()
                Text(trailing)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func taskRow(_ task: PlannerTask) -> some View {
        row(done: task.isDone,
            title: (task.isDeadline ? "🚩 " : "") + task.title,
            trailing: task.timeText) {
            task.isDone.toggle()
        }
        // .contextMenu = il menu che compare tenendo premuto
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { context.delete(task) }
            } label: {
                Label(tr("Delete", "Elimina"), systemImage: "trash")
            }
        }
    }

    /// La riga grigia "niente in programma" (solo se la lista è vuota)
    @ViewBuilder
    private func emptyRow(_ text: String, visible: Bool) -> some View {
        if visible {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 68)
                .padding(.vertical, 14)
        }
    }

    // MARK: - Acqua

    private var waterRow: some View {
        let glasses = waterLog?.glasses ?? 0
        let goal = AppSettings.waterGoal

        return HStack(spacing: 6) {
            ForEach(0..<goal, id: \.self) { index in
                Button {
                    // Tocco una goccia: riempio fino a lì (se è l'ultima piena, la svuoto)
                    setGlasses(index + 1 == glasses ? index : index + 1)
                } label: {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(index < glasses ? Theme.accent : Theme.highlight)
                        // iOS 17: la goccia "rimbalza" quando si riempie
                        .symbolEffect(.bounce, value: index < glasses)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tr("Glass \(index + 1)", "Bicchiere \(index + 1)"))
            }
            Spacer(minLength: 4)
            Text("\(glasses) / \(goal)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.secondary)
        }
        .padding(.horizontal, 18)
        .frame(height: 76)
        .cardBackground(radius: 18)
    }

    private func setGlasses(_ value: Int) {
        let clamped = max(0, min(value, AppSettings.waterGoal))
        if let waterLog {
            waterLog.glasses = clamped
        } else {
            context.insert(WaterLog(day: day, glasses: clamped))
        }
        Haptics.tap()
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        PlannerView(day: .constant(.now))
            .background(Theme.background)
    }
    .modelContainer(PreviewData.container)
}
