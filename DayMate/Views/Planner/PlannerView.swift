//
//  PlannerView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Planner" di Sketch: la giornata in una schermata.
//   - data + settimana
//   - la card lilla "TODAY" con le caselline: i passi di studio del giorno (dal piano
//     degli esami) + le tue cose da fare. Le frecce ◁ ▷ cambiano giorno.
//   - la card dell'acqua: 8 gocce, "+1 glass", e il bradipo che beve
//
//  Perché i passi d'esame anche qui? Così il Planner non è un'altra lista da tenere
//  aggiornata a mano: lo studio di oggi c'è già, tu aggiungi solo il resto.
//

import SwiftUI
import SwiftData
import TipKit

struct PlannerView: View {
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \PlannerTask.createdAt) private var allTasks: [PlannerTask]
    @Query private var waterLogs: [WaterLog]
    @Query(sort: \Exam.date) private var exams: [Exam]

    /// Il giorno mostrato (condiviso con le altre sezioni del Planner)
    @Binding var day: Date
    var embedded = false

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var newTask = ""
    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var newTaskFocused: Bool

    private var calendar: Calendar { .current }

    private var isToday: Bool { calendar.isDateInToday(day) }

    private var tasks: [PlannerTask] {
        allTasks.filter { calendar.isDate($0.day, inSameDayAs: day) }
    }

    /// Un passo di studio con il suo esame
    private struct StudyItem: Identifiable {
        let exam: Exam
        let step: StudyStep
        var id: PersistentIdentifier { step.persistentModelID }
    }

    /// I passi di studio previsti per il giorno scelto, esame per esame
    private var studySteps: [StudyItem] {
        exams.filter { !$0.isPast }.flatMap { exam -> [StudyItem] in
            let dayPlan = StudyPlanner.plan(for: exam).days.first { calendar.isDate($0.date, inSameDayAs: day) }
            return (dayPlan?.steps ?? []).map { StudyItem(exam: exam, step: $0) }
        }
    }

    private var waterLog: WaterLog? {
        waterLogs.first { calendar.isDate($0.day, inSameDayAs: day) }
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !embedded {
                    BackPill(title: "Home")
                }

                Text(day.longDayText)
                    .font(.dmSerifBig)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, embedded ? 0 : 6)

                WeekStrip(selected: $day, marked: exams.map(\.date))

                // 💡 Suggerimento di TipKit
                TipView(PlannerTip())
                    .tint(Theme.rust)

                Text(isToday ? tr("TODAY", "OGGI")
                             : day.formatted(.dateTime.weekday(.wide).locale(L10n.locale)).uppercased())
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.rust)
                    .padding(.top, 10)

                // Le frecce ◁ ▷ ai lati della card, come in Sketch
                HStack(spacing: 2) {
                    arrow("arrowtriangle.left", days: -1)
                    todoCard
                    arrow("arrowtriangle.right", days: 1)
                }

                WaterCard(glasses: waterLog?.glasses ?? 0,
                          goal: AppSettings.waterGoal,
                          onSet: setGlasses)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
        .dmScreen(standalone: !embedded)
    }

    // MARK: - Card lilla

    private var todoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(studySteps) { item in
                Button {
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation(.snappy) {
                        item.step.isDone.toggle()
                        item.step.completedAt = item.step.isDone ? .now : nil
                    }
                    if item.step.isDone { Haptics.tap() }
                } label: {
                    row(isDone: item.step.isDone,
                        title: item.step.title,
                        detail: "\(item.exam.name) · ≈ \(item.exam.estimatedMinutes(for: item.step)) min")
                }
                .buttonStyle(.plain)
            }

            ForEach(tasks) { task in
                Button {
                    withAnimation(.snappy) { task.isDone.toggle() }
                    if task.isDone { Haptics.tap() }
                } label: {
                    row(isDone: task.isDone, title: task.title,
                        detail: task.isDeadline ? tr("🚩 Deadline", "🚩 Scadenza") : nil)
                }
                .buttonStyle(.plain)
                // .contextMenu = il menu che compare tenendo premuto
                .contextMenu {
                    Button(role: .destructive) {
                        withAnimation { context.delete(task) }
                    } label: {
                        Label(tr("Delete", "Elimina"), systemImage: "trash")
                    }
                }
            }

            // Riga per aggiungere: una casella vuota + il testo
            HStack(spacing: 12) {
                SquareCheck(isOn: false)
                TextField(tr("Add something…", "Aggiungi qualcosa…"), text: $newTask)
                    .font(.subheadline)
                    .focused($newTaskFocused)
                    .submitLabel(.done)
                    .onSubmit(addTask)
            }

            if studySteps.isEmpty && tasks.isEmpty {
                Text(tr("Nothing planned. Write the first thing above; long-press an item to delete it.",
                        "Niente in programma. Scrivi la prima cosa qui sopra; tieni premuto per eliminare."))
                    .font(.caption)
                    .foregroundStyle(Theme.mute)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .topLeading)
        .background(Theme.lilacSoft, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
            .strokeBorder(Theme.lilac, lineWidth: 1.5))
    }

    private func row(isDone: Bool, title: String, detail: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            SquareCheck(isOn: isDone, tint: Theme.cocoa)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .strikethrough(isDone)
                    .foregroundStyle(isDone ? Theme.mute : Theme.ink)
                    .multilineTextAlignment(.leading)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(Theme.rust)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }

    private func arrow(_ symbol: String, days: Int) -> some View {
        Button {
            Haptics.tap()
            if let date = calendar.date(byAdding: .day, value: days, to: day) {
                withAnimation(.snappy) { day = date }
            }
        } label: {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(Theme.ink)
                .frame(width: 22, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(days < 0 ? tr("Previous day", "Giorno precedente") : tr("Next day", "Giorno successivo"))
    }

    // MARK: - Azioni

    private func addTask() {
        let title = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        context.insert(PlannerTask(title: title, day: day))
        newTask = ""
        newTaskFocused = true
        Haptics.tap()
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

// MARK: - Card dell'acqua

private struct WaterCard: View {
    let glasses: Int
    let goal: Int
    var onSet: (Int) -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tr("Water", "Acqua"))
                        .font(.dmTitle2)
                        .foregroundStyle(Theme.ink)
                    Text(tr("\(glasses) of \(goal) glasses", "\(glasses) bicchieri su \(goal)"))
                        .font(.subheadline.italic())
                        .foregroundStyle(Theme.ink.opacity(0.8))
                }

                HStack(spacing: 2) {
                    ForEach(0..<goal, id: \.self) { index in
                        Button {
                            // Tocco una goccia: riempio fino a lì (se è l'ultima piena, la svuoto)
                            onSet(index + 1 == glasses ? index : index + 1)
                        } label: {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 26))
                                // iOS 17: la goccia "rimbalza" quando si riempie
                                .symbolEffect(.bounce, value: index < glasses)
                                .foregroundStyle(index < glasses ? Theme.water : Theme.cream)
                                .overlay(
                                    Image(systemName: "drop")
                                        .font(.system(size: 26))
                                        .foregroundStyle(Theme.cocoa.opacity(index < glasses ? 0.8 : 0.25))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(tr("Glass \(index + 1)", "Bicchiere \(index + 1)"))
                    }
                }
                .padding(.trailing, 50)

                Button {
                    onSet(glasses + 1)
                } label: {
                    Text(tr("+1 glass", "+1 bicchiere"))
                }
                .buttonStyle(PillButtonStyle(variant: .cream, height: 40))
                .frame(maxWidth: 200)
                .disabled(glasses >= goal)
                .padding(.leading, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SlothView(pose: .drinking)
                .frame(width: 74, height: 98)
                .offset(x: 10, y: 12)
        }
        .padding(18)
        .background(Theme.skySoft, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        PlannerView(day: .constant(.now))
    }
    .modelContainer(PreviewData.container)
}
