//
//  PlannerModeView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🗓️ La modalità Planner: si apre quando nella schermata iniziale tocchi "Plan my day".
//
//   ‹ Home                            (+)
//   Plan
//   M T W [T] F S S                   ← la settimana (il giorno scelto è viola)
//   …contenuto della sezione…
//   ─────────────────────────────────────
//    ✅ Giorno   📅 Settimana   🚩 Scadenze   ⚙️ Impostazioni     ← barra in basso (TabView)
//
//   - Giorno       → la schermata "Plan" di Sketch: settimana, studio, impegni, acqua
//   - Settimana    → i 7 giorni in colpo d'occhio
//   - Scadenze     → consegne, pagamenti, esami… con il conto alla rovescia
//   - Impostazioni → obiettivo acqua, lingua, cambio modalità
//
//  Giorno, Settimana e Scadenze condividono lo stesso giorno scelto: tocchi un giorno
//  nella Settimana e si apre quel giorno. Il "+" apre "Add to your day".
//

import SwiftUI
import SwiftData

/// Le 4 sezioni della modalità Planner
enum PlannerTab: String, CaseIterable {
    case day, week, deadlines, settings

    /// Il titolo grande in cima alla sezione
    var title: String {
        switch self {
        case .day:       return tr("Plan", "Pianifica")
        case .week:      return tr("Week", "Settimana")
        case .deadlines: return tr("Deadlines", "Scadenze")
        case .settings:  return tr("Settings", "Impostazioni")
        }
    }

    /// Il nome corto nella barra in basso
    var shortTitle: String {
        switch self {
        case .day:       return tr("Day", "Giorno")
        case .week:      return tr("Week", "Settimana")
        case .deadlines: return tr("Deadlines", "Scadenze")
        case .settings:  return tr("Settings", "Impostazioni")
        }
    }

    var icon: String {
        switch self {
        case .day:       return "checklist"
        case .week:      return "calendar"
        case .deadlines: return "flag.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

struct PlannerModeView: View {
    // @Binding = la sezione aperta appartiene a RootView (così resta uguale se cambio lingua)
    @Binding var tab: PlannerTab
    /// Torna alla schermata iniziale ("Studiare o organizzare la giornata?")
    var onChangeMode: () -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var day = Calendar.current.startOfDay(for: .now)
    @State private var showingAddTask = false

    var body: some View {
        // TabView = la barra delle sezioni in basso
        TabView(selection: $tab) {
            // ✅ Giorno
            NavigationStack {
                // come in Sketch: niente data sotto "Plan", la mostra già la settimana
                section(.day) {
                    PlannerView(day: $day)
                }
                .navigationDestination(for: Exam.self) { exam in
                    ExamDetailView(exam: exam)
                }
            }
            .tabItem { Label(PlannerTab.day.shortTitle, systemImage: PlannerTab.day.icon) }
            .tag(PlannerTab.day)

            // 📅 Settimana
            NavigationStack {
                section(.week) {
                    PlannerWeekView(day: $day) { chosen in
                        // tocco un giorno → lo apro nella sezione "Giorno"
                        day = chosen
                        tab = .day
                    }
                }
            }
            .tabItem { Label(PlannerTab.week.shortTitle, systemImage: PlannerTab.week.icon) }
            .tag(PlannerTab.week)

            // 🚩 Scadenze
            NavigationStack {
                section(.deadlines) {
                    PlannerDeadlinesView()
                }
                // .navigationDestination: "quando qualcuno apre un valore di questo tipo, mostra questa vista"
                .navigationDestination(for: Exam.self) { exam in
                    ExamDetailView(exam: exam)
                }
            }
            .tabItem { Label(PlannerTab.deadlines.shortTitle, systemImage: PlannerTab.deadlines.icon) }
            .tag(PlannerTab.deadlines)

            // ⚙️ Impostazioni
            NavigationStack {
                SettingsView(mode: .planner, onChangeMode: onChangeMode)
                    .dmTabBar()
            }
            .tabItem { Label(PlannerTab.settings.shortTitle, systemImage: PlannerTab.settings.icon) }
            .tag(PlannerTab.settings)
        }
        .tint(Theme.main)
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet(day: day, isDeadline: tab == .deadlines)
        }
    }

    /// Una sezione: intestazione con il "+" in alto + il suo contenuto
    private func section<Content: View>(_ tab: PlannerTab,
                                        subtitle: String? = nil,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            ModeHeader(onHome: onChangeMode, title: tab.title, subtitle: subtitle,
                       addLabel: tr("Add to your day", "Aggiungi alla giornata"),
                       onAdd: { showingAddTask = true })
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .dmScreen()
        .dmTabBar()
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
        calendar.firstWeekday = 2   // la settimana parte dal lunedì
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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    weekButton("chevron.left", weeks: -1)
                    Spacer()
                    Text(weekTitle)
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    weekButton("chevron.right", weeks: 1)
                }
                .padding(.bottom, 4)

                let allPlans = plans
                ForEach(days, id: \.self) { date in
                    Button {
                        onOpenDay(date)
                    } label: {
                        dayRow(date, plans: allPlans)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    /// "26 Oct – 1 Nov"
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
        let studyMinutes = plans.compactMap { plan in
            plan.days.first { calendar.isDate($0.date, inSameDayAs: date) }?.minutes
        }.reduce(0, +)
        let examsToday = exams.filter { calendar.isDate($0.date, inSameDayAs: date) }
        let deadlines = dayTasks.filter(\.isDeadline)
        let glasses = waterLogs.first { calendar.isDate($0.day, inSameDayAs: date) }?.glasses ?? 0
        let isToday = calendar.isDateInToday(date)

        return HStack(spacing: 14) {
            // il "quadratino" del giorno, come nella settimana in alto
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.narrow).locale(L10n.locale)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isToday ? Theme.background : Theme.secondary)
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(isToday ? Theme.background : Theme.text)
            }
            .frame(width: 46, height: 58)
            .background(isToday ? Theme.main : Theme.highlight,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                ForEach(examsToday) { exam in
                    Label(tr("\(exam.name) exam", "Esame di \(exam.name)"), systemImage: "flag.checkered")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                }
                ForEach(deadlines) { task in
                    Label(task.title, systemImage: "flag.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .lineLimit(1)
                }
                if !dayTasks.isEmpty {
                    Label(tr("\(doneTasks)/\(dayTasks.count) tasks", "\(doneTasks)/\(dayTasks.count) attività"),
                          systemImage: "checklist")
                }
                if studyMinutes > 0 {
                    Label(tr("\(studyMinutes.asDuration) of study", "\(studyMinutes.asDuration) di studio"),
                          systemImage: "book")
                }
                if glasses > 0 {
                    Label("\(glasses) / \(AppSettings.waterGoal)", systemImage: "drop.fill")
                }
                if examsToday.isEmpty && dayTasks.isEmpty && studyMinutes == 0 && glasses == 0 {
                    Text(tr("Free day", "Giorno libero"))
                }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.secondary)

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.secondary)
        }
        .padding(12)
        .cardBackground(radius: 18)
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
                .foregroundStyle(Theme.lightMain)
                .frame(width: 38, height: 38)
                .background(Theme.card, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(weeks < 0 ? tr("Previous week", "Settimana precedente") : tr("Next week", "Settimana successiva"))
    }
}

// MARK: - Scadenze

struct PlannerDeadlinesView: View {
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \Exam.date) private var exams: [Exam]
    @Query(filter: #Predicate<PlannerTask> { $0.isDeadline }, sort: \PlannerTask.day)
    private var deadlineTasks: [PlannerTask]

    private var upcomingExams: [Exam] { exams.filter { !$0.isPast } }

    /// Solo le scadenze da oggi in poi (quelle passate non servono più)
    private var upcomingDeadlines: [PlannerTask] {
        let today = Calendar.current.startOfDay(for: .now)
        return deadlineTasks.filter { $0.day >= today }
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if upcomingExams.isEmpty && upcomingDeadlines.isEmpty {
                    VStack(spacing: 12) {
                        GlowRings(size: 200) {
                            BlobView(pose: .ready)
                        }
                        Text(tr("No deadlines", "Nessuna scadenza"))
                            .font(.system(.title3, weight: .bold))
                            .foregroundStyle(Theme.text)
                        Text(tr("Tap + and turn on \"It's a deadline\": a hand-in, a payment, an appointment.",
                                "Tocca + e attiva \"È una scadenza\": una consegna, un pagamento, un appuntamento."))
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                }

                ForEach(upcomingDeadlines) { task in
                    deadlineRow(title: task.title, date: task.day, done: task.isDone) {
                        task.isDone.toggle()
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation { context.delete(task) }
                        } label: {
                            Label(tr("Delete", "Elimina"), systemImage: "trash")
                        }
                    }
                }

                // Gli esami (se si usa anche la modalità Studio): tocco e apro il dettaglio
                ForEach(upcomingExams) { exam in
                    NavigationLink(value: exam) {
                        deadlineRow(title: tr("\(exam.name) exam", "Esame di \(exam.name)"),
                                    date: exam.date, done: false, action: nil)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    /// Una scadenza: il "foglietto" con la data, il titolo e quanti giorni mancano
    private func deadlineRow(title: String, date: Date, done: Bool, action: (() -> Void)?) -> some View {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now),
                                                   to: Calendar.current.startOfDay(for: date)).day ?? 0

        return HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(date.formatted(.dateTime.month(.abbreviated).locale(L10n.locale)).uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.secondary)
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(.title2, weight: .bold))
                    .foregroundStyle(Theme.text)
            }
            .frame(width: 52, height: 56)
            .background(Theme.highlight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.dmRowTitle)
                    .foregroundStyle(done ? Theme.secondary : Theme.text)
                    .strikethrough(done)
                Text(days == 0 ? tr("Today", "Oggi")
                     : days == 1 ? tr("Tomorrow", "Domani")
                     : tr("In \(days) days", "Tra \(days) giorni"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            Spacer(minLength: 0)

            if let action {
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { action() }
                } label: {
                    CheckCircle(state: done ? .done : .todo)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tr("Done", "Fatto"))
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondary)
            }
        }
        .padding(12)
        .cardBackground(radius: 18)
    }
}

// MARK: - "Add to your day" (schermata 09 di Sketch)

struct AddTaskSheet: View {
    // dismiss() chiude il foglio
    @Environment(\.dismiss) private var dismiss
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var title = ""
    @State private var day: Date
    @State private var kind: TaskKind = .duty
    @State private var time: Date
    @State private var duration = 30
    @State private var isDeadline: Bool
    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var focused: Bool

    private let durations = [15, 30, 45, 60, 90, 120, 180]

    init(day: Date, isDeadline: Bool = false) {
        // Con @State dentro un init si usa il "_" davanti al nome
        _day = State(initialValue: day)
        _isDeadline = State(initialValue: isDeadline)
        // orario proposto: la prossima ora piena (es. adesso 14:20 → 15:00)
        let nextHour = Calendar.current.nextDate(after: .now, matching: DateComponents(minute: 0),
                                                 matchingPolicy: .nextTime) ?? .now
        _time = State(initialValue: nextHour)
    }

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(tr("Add to your day", "Aggiungi alla giornata"))
                    .font(.dmCardTitle)
                    .foregroundStyle(Theme.text)
                    .padding(.top, 24)

                TextField(tr("e.g. Gym, lab report…", "es. Palestra, relazione…"), text: $title)
                    .font(.body)
                    .foregroundStyle(Theme.text)
                    .focused($focused)
                    .submitLabel(.done)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 52)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                // TYPE: Study / Duty / Free time
                SectionHeader(text: tr("Type", "Tipo"))
                HStack(spacing: 10) {
                    ForEach(TaskKind.allCases) { option in
                        Button {
                            Haptics.tap()
                            kind = option
                        } label: {
                            VStack(spacing: 10) {
                                IconTile(systemName: option.icon, inverted: kind == option)
                                Text(option.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(kind == option ? Theme.background : Theme.text)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 96)
                            .background(kind == option ? Theme.main : Theme.card,
                                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // WHEN: ora e durata come in Sketch; poi, in più, giorno e "scadenza"
                SectionHeader(text: tr("When", "Quando"))
                VStack(spacing: 0) {
                    DatePicker(tr("Time", "Ora"), selection: $time, displayedComponents: .hourAndMinute)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 54)
                    Rectangle().fill(Theme.highlight).frame(height: 1).padding(.leading, 18)
                    HStack {
                        Text(tr("Duration", "Durata"))
                        Spacer()
                        Picker(tr("Duration", "Durata"), selection: $duration) {
                            ForEach(durations, id: \.self) { Text("\($0) min").tag($0) }
                        }
                        .labelsHidden()
                    }
                    .padding(.horizontal, 18)
                    .frame(minHeight: 54)
                    Rectangle().fill(Theme.highlight).frame(height: 1).padding(.leading, 18)
                    // extra rispetto a Sketch: il giorno (di default quello aperto nel Planner)
                    DatePicker(tr("Day", "Giorno"), selection: $day, displayedComponents: .date)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 54)
                    Rectangle().fill(Theme.highlight).frame(height: 1).padding(.leading, 18)
                    Toggle(isOn: $isDeadline) {
                        Label(tr("It's a deadline", "È una scadenza"), systemImage: "flag.fill")
                    }
                    .tint(Theme.accent)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 54)
                }
                .font(.system(.callout, weight: .medium))
                .foregroundStyle(Theme.text)
                .cardBackground(radius: 18)
            }
            .padding(.horizontal, 20)
        }
        .safeAreaInset(edge: .bottom) {
            Button(tr("Add", "Aggiungi"), action: save)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canAdd)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Theme.background)
        }
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .preferredColorScheme(.dark)
        // .onAppear viene chiamato quando il foglio compare: apro subito la tastiera
        .onAppear { focused = true }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // L'orario deve essere nel giorno scelto: prendo ore e minuti da `time` e li metto su `day`
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        let finalTime = Calendar.current.date(bySettingHour: parts.hour ?? 9, minute: parts.minute ?? 0,
                                              second: 0, of: day)
        context.insert(PlannerTask(title: trimmed, day: day, kind: kind, time: finalTime,
                                   durationMinutes: duration, isDeadline: isDeadline))
        Haptics.success()
        dismiss()
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    PlannerModeView(tab: .constant(.day), onChangeMode: {})
        .modelContainer(PreviewData.container)
}
