//
//  PlannerModeView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🗓️ La modalità "Fai un planner": la tua giornata e la tua settimana, sotto una barra in alto.
//  È la "home" di chi sceglie Planner all'inizio.
//
//   [ Giorno ] [ Settimana ] [ Scadenze ]              + Attività
//
//   - Giorno    → la card lilla con le cose da fare (e i passi di studio del giorno) + l'acqua
//   - Settimana → i 7 giorni in colpo d'occhio: attività, studio, esami, acqua
//   - Scadenze  → le tue scadenze (+ quelle degli esami, se usi anche Studio)
//
//  Tutte e tre le sezioni condividono lo stesso giorno scelto: tocchi un giorno nella
//  Settimana e si apre quel giorno.
//

import SwiftUI
import SwiftData

/// Le 3 sezioni della modalità Planner
enum PlannerTab: String, CaseIterable {
    case day, week, deadlines

    var title: String {
        switch self {
        case .day:       return tr("Day", "Giorno")
        case .week:      return tr("Week", "Settimana")
        case .deadlines: return tr("Deadlines", "Scadenze")
        }
    }

    var icon: String {
        switch self {
        case .day:       return "checklist"
        case .week:      return "calendar"
        case .deadlines: return "flag.checkered"
        }
    }

    /// La stessa sezione pronta per la barra in alto
    var item: TabItem {
        TabItem(id: rawValue, title: title, icon: icon)
    }
}

struct PlannerModeView: View {
    /// Il percorso di navigazione (tenuto in RootView)
    @Binding var path: NavigationPath

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var tab: PlannerTab = .day
    @State private var day = Calendar.current.startOfDay(for: .now)
    @State private var showingAddTask = false

    var body: some View {
        NavigationStack(path: $path) {
            content
                // .navigationDestination: "quando qualcuno apre un valore di questo tipo, mostra questa vista"
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .settings: SettingsView()
                    }
                }
                .navigationDestination(for: Exam.self) { exam in
                    ExamDetailView(exam: exam)
                }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SpaceHeader(mode: .planner,
                        title: tab.title,
                        items: PlannerTab.allCases.map { $0.item },
                        selectedID: tab.rawValue,
                        onSelect: { id in
                            if let newTab = PlannerTab(rawValue: id) {
                                // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                                withAnimation(.snappy) { tab = newTab }
                            }
                        },
                        addLabel: tab == .deadlines ? tr("Deadline", "Scadenza") : tr("Task", "Attività"),
                        onAdd: { showingAddTask = true })

            Group {
                switch tab {
                case .day:
                    PlannerView(day: $day, embedded: true)
                case .week:
                    PlannerWeekView(day: $day) { chosen in
                        day = chosen
                        tab = .day
                    }
                case .deadlines:
                    PlannerDeadlinesView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        }
        .dmScreen()
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet(day: day, isDeadline: tab == .deadlines)
        }
    }
}

// MARK: - Settimana

struct PlannerWeekView: View {
    @Binding var day: Date
    /// Toccando un giorno lo apro nella sezione "Giorno"
    var onOpenDay: (Date) -> Void

    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \PlannerTask.createdAt) private var tasks: [PlannerTask]
    @Query private var waterLogs: [WaterLog]
    @Query(sort: \Exam.date) private var exams: [Exam]

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    /// I 7 giorni della settimana del giorno scelto (dal lunedì alla domenica).
    /// dateInterval(of: .weekOfYear) mi dà l'inizio della settimana, poi aggiungo 0…6 giorni.
    private var days: [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: day) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    /// Piani di studio calcolati una volta per tutta la settimana
    private var plans: [StudyPlan] {
        exams.filter { !$0.isPast }.map { StudyPlanner.plan(for: $0) }
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    weekButton("chevron.left", weeks: -1)
                    Spacer()
                    Text(weekTitle)
                        .font(.dmSerifBig)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    weekButton("chevron.right", weeks: 1)
                }

                let allPlans = plans
                ForEach(days, id: \.self) { date in
                    Button {
                        onOpenDay(date)
                    } label: {
                        dayRow(date, plans: allPlans)
                    }
                    .buttonStyle(.plain)
                }

                Text(tr("Tap a day to open it.", "Tocca un giorno per aprirlo."))
                    .font(.caption)
                    .foregroundStyle(Theme.mute)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    private var weekTitle: String {
        guard let first = days.first, let last = days.last else { return "" }
        let style = Date.FormatStyle.dateTime.day().month(.abbreviated).locale(L10n.locale)
        return "\(first.formatted(style)) – \(last.formatted(style))"
    }

    /// Una riga della settimana. Prima calcolo tutto quello che c'è in quel giorno
    /// (attività, passi di studio, esami, acqua), poi lo mostro.
    /// 📌 filter = "tieni solo gli elementi che rispettano la condizione"
    private func dayRow(_ date: Date, plans: [StudyPlan]) -> some View {
        let dayTasks = tasks.filter { calendar.isDate($0.day, inSameDayAs: date) }
        let doneTasks = dayTasks.filter(\.isDone).count
        let studySteps = plans.compactMap { plan in
            plan.days.first { calendar.isDate($0.date, inSameDayAs: date) }
        }.flatMap(\.steps)
        let studyMinutes = plans.compactMap { plan in
            plan.days.first { calendar.isDate($0.date, inSameDayAs: date) }?.minutes
        }.reduce(0, +)
        let examsToday = exams.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let deadlinesToday = dayTasks.filter(\.isDeadline)
        let glasses = waterLogs.first { calendar.isDate($0.day, inSameDayAs: date) }?.glasses ?? 0
        let isToday = calendar.isDateInToday(date)

        return HStack(alignment: .center, spacing: 14) {
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.abbreviated).locale(L10n.locale)).capitalized)
                    .font(.system(.caption, design: .serif, weight: .bold))
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(.title2, design: .serif, weight: .bold))
            }
            .foregroundStyle(isToday ? .white : Theme.ink)
            .frame(width: 52, height: 58)
            .background(isToday ? Theme.cocoa : Theme.lilacSoft,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(examsToday) { exam in
                    Label(tr("\(exam.name) exam", "Esame di \(exam.name)"), systemImage: "flag.checkered")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.rust)
                }
                ForEach(deadlinesToday) { task in
                    Label(task.title, systemImage: "flag.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.rust)
                        .lineLimit(1)
                }
                if !dayTasks.isEmpty {
                    Label(tr("\(doneTasks)/\(dayTasks.count) tasks", "\(doneTasks)/\(dayTasks.count) attività"),
                          systemImage: "checklist")
                }
                if !studySteps.isEmpty {
                    Label(tr("\(studySteps.count) study steps · \(studyMinutes.asDuration)",
                             "\(studySteps.count) passi di studio · \(studyMinutes.asDuration)"),
                          systemImage: "book.fill")
                }
                if glasses > 0 {
                    Label(tr("\(glasses) glasses of water", "\(glasses) bicchieri d'acqua"), systemImage: "drop.fill")
                }
                if examsToday.isEmpty && dayTasks.isEmpty && studySteps.isEmpty && glasses == 0 {
                    Text(tr("Free day", "Giorno libero"))
                        .foregroundStyle(Theme.mute)
                }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.ink)

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mute.opacity(0.6))
        }
        .dmCard(radius: 22, padding: 12)
    }

    private func weekButton(_ symbol: String, weeks: Int) -> some View {
        Button {
            Haptics.tap()
            if let date = calendar.date(byAdding: .day, value: 7 * weeks, to: day) {
                withAnimation(.snappy) { day = date }
            }
        } label: {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(Theme.ink)
                .frame(width: 40, height: 40)
                .background(Theme.pillGray, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(weeks < 0 ? tr("Previous week", "Settimana precedente") : tr("Next week", "Settimana successiva"))
    }
}

// MARK: - Scadenze

struct PlannerDeadlinesView: View {
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context
    @Query(sort: \Exam.date) private var exams: [Exam]
    @Query(filter: #Predicate<PlannerTask> { $0.isDeadline }, sort: \PlannerTask.day)
    private var deadlineTasks: [PlannerTask]

    private var upcoming: [Exam] { exams.filter { !$0.isPast } }

    /// Solo le scadenze da oggi in poi (quelle passate non servono più)
    private var upcomingDeadlines: [PlannerTask] {
        let today = Calendar.current.startOfDay(for: .now)
        return deadlineTasks.filter { $0.day >= today }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(upcomingDeadlines) { task in
                    deadlineRow(task)
                }

                if upcoming.isEmpty && upcomingDeadlines.isEmpty {
                    VStack(spacing: 10) {
                        SlothView(pose: .calendar)
                            .frame(height: 140)
                        Text(tr("No deadlines", "Nessuna scadenza"))
                            .font(.dmTitle2)
                            .foregroundStyle(Theme.ink)
                        Text(tr("Tap \"+ Deadline\" to add one: a hand-in, a payment, an appointment. It will also appear in your week.",
                                "Tocca \"+ Scadenza\" per aggiungerne una: una consegna, un pagamento, un appuntamento. Comparirà anche nella settimana."))
                            .font(.subheadline)
                            .foregroundStyle(Theme.mute)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)
                }

                ForEach(upcoming) { exam in
                    // Collegamento allo Studio: tocchi e apri il dettaglio dell'esame
                    NavigationLink(value: exam) {
                        HStack(spacing: 14) {
                            VStack(spacing: 0) {
                                Text(exam.date.formatted(.dateTime.month(.abbreviated).locale(L10n.locale)).uppercased())
                                    .font(.caption.weight(.bold))
                                Text("\(Calendar.current.component(.day, from: exam.date))")
                                    .font(.system(.title, design: .serif, weight: .bold))
                            }
                            .foregroundStyle(Theme.ink)
                            .frame(width: 60, height: 64)
                            .background(Theme.honey, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(exam.name)
                                    .font(.dmHeadline)
                                    .foregroundStyle(Theme.ink)
                                Text(exam.countdownText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.rust)
                                ProgressView(value: exam.progress)
                                    .tint(Theme.honey)
                                Text(exam.stepsDoneText)
                                    .font(.caption)
                                    .foregroundStyle(Theme.mute)
                            }
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.mute.opacity(0.6))
                        }
                        .dmCard(radius: 22, padding: 14)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
    }

    private func deadlineRow(_ task: PlannerTask) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: task.day).day ?? 0

        return HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(task.day.formatted(.dateTime.month(.abbreviated).locale(L10n.locale)).uppercased())
                    .font(.caption.weight(.bold))
                Text("\(Calendar.current.component(.day, from: task.day))")
                    .font(.system(.title, design: .serif, weight: .bold))
            }
            .foregroundStyle(Theme.ink)
            .frame(width: 60, height: 64)
            .background(Theme.lilac, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.dmHeadline)
                    .foregroundStyle(Theme.ink)
                    .strikethrough(task.isDone)
                Text(days == 0 ? tr("Today", "Oggi")
                     : days == 1 ? tr("Tomorrow", "Domani")
                     : tr("In \(days) days", "Tra \(days) giorni"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.rust)
            }
            Spacer(minLength: 0)
            Button {
                withAnimation(.snappy) { task.isDone.toggle() }
                if task.isDone { Haptics.success() }
            } label: {
                SquareCheck(isOn: task.isDone, tint: Theme.cocoa)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(tr("Done", "Fatto"))
        }
        .dmCard(radius: 22, padding: 14)
        // .contextMenu = il menu che compare tenendo premuto
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { context.delete(task) }
            } label: {
                Label(tr("Delete", "Elimina"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Nuova attività

struct AddTaskSheet: View {
    // dismiss() chiude questa schermata (o il foglio) e torna indietro
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var day: Date
    @State private var isDeadline: Bool
    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var focused: Bool

    init(day: Date, isDeadline: Bool = false) {
        _day = State(initialValue: day)
        _isDeadline = State(initialValue: isDeadline)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScreenHeader(eyebrow: "Planner",
                         title: isDeadline ? tr("New deadline", "Nuova scadenza") : tr("New task", "Nuova attività"))

            TextField(tr("E.g. Print the notes", "Es. Stampare gli appunti"), text: $title)
                .font(.title3.weight(.semibold))
                .focused($focused)
                .submitLabel(.done)
                .onSubmit(save)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Theme.cream, in: Capsule())

            DatePicker(tr("Day", "Giorno"), selection: $day, displayedComponents: .date)
                .font(.headline)
                .foregroundStyle(Theme.ink)

            Toggle(isOn: $isDeadline) {
                Label(tr("It's a deadline", "È una scadenza"), systemImage: "flag.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.honey)

            Spacer(minLength: 0)

            Button(tr("Add", "Aggiungi"), action: save)
                .buttonStyle(PillButtonStyle(variant: .dark))
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(24)
        .background(Theme.paper.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        // .onAppear viene chiamato quando la schermata compare
        .onAppear { focused = true }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(PlannerTask(title: trimmed, day: day, isDeadline: isDeadline))
        Haptics.success()
        dismiss()
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    PlannerModeView(path: .constant(NavigationPath()))
        .modelContainer(PreviewData.container)
}
