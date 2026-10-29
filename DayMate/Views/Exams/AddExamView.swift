//
//  AddExamView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "New Exam" di Sketch.
//
//  Sketch mostra: nome, data, "Materials" (le chip Ch 01, Ch 02…) e la card gialla
//  con i "tiny steps" e la pista tartaruga → lepre.
//  Sotto il cofano resta il piano REALISTICO della v2:
//   - ogni chip è un argomento con pagine e difficoltà (tocca la chip per cambiarle)
//   - la pista tartaruga → lepre sceglie il RITMO: quanto tempo al giorno puoi dedicare
//     (🐢 30 min … 🐇 5 h). La card dice subito se il piano ci sta.
//   - il tipo d'esame (teoria / esercizi / misto) decide se ci sono esercizi e simulazioni
//

import SwiftUI
import SwiftData

struct AddExamView: View {
    // dismiss() chiude questa schermata (o il foglio) e torna indietro
    @Environment(\.dismiss) private var dismiss
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var name = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 21, to: .now) ?? .now
    @State private var kind: ExamKind = .mixed
    @State private var paceIndex = 3          // indice in dailyOptions → 120 min
    @State private var topics: [TopicDraft] = []

    @State private var showingDatePicker = false
    /// Argomento che sto modificando nel foglio (nil = foglio chiuso)
    @State private var editingTopic: TopicDraft?

    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var nameFocused: Bool

    /// Ritmi possibili: dalla tartaruga alla lepre
    private let dailyOptions = [30, 60, 90, 120, 180, 240, 300]

    private var dailyMinutes: Int { dailyOptions[min(max(paceIndex, 0), dailyOptions.count - 1)] }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && !topics.isEmpty
    }

    /// Giorni di studio disponibili (fino al giorno prima dell'esame)
    private var studyDays: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: .now),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        return max(days, 1)
    }

    private var daysLeft: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now),
                                       to: calendar.startOfDay(for: date)).day ?? 0
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BackPill(title: tr("Exams", "Esami"))

                ScreenHeader(eyebrow: tr("Study", "Studio"), title: tr("New Exam", "Nuovo esame"))

                nameField
                dateRow
                kindPicker
                materials
                planCard

                Button(tr("Save", "Salva"), action: save)
                    .buttonStyle(PillButtonStyle(variant: .dark))
                    .disabled(!canSave)
                    .padding(.top, 4)

                if !canSave {
                    Text(tr("Add a name and at least one topic to create your plan.",
                            "Aggiungi un nome e almeno un argomento per creare il piano."))
                        .font(.footnote)
                        .foregroundStyle(Theme.mute)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
        .dmScreen()
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(item: $editingTopic) { topic in
            TopicEditorSheet(topic: topic,
                             isNew: !topics.contains { $0.id == topic.id },
                             onSave: saveTopics,
                             onDelete: { id in topics.removeAll { $0.id == id } })
        }
    }

    // MARK: - Campi

    private var nameField: some View {
        TextField(tr("Exam name", "Nome dell'esame"), text: $name)
            .font(.dmTitle2)
            .foregroundStyle(Theme.ink)
            .textInputAutocapitalization(.words)
            .focused($nameFocused)
            .submitLabel(.done)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Theme.cream, in: Capsule())
            .overlay(Capsule().strokeBorder(.black.opacity(0.04)))
    }

    private var dateRow: some View {
        VStack(spacing: 0) {
            Button {
                nameFocused = false
                // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                withAnimation(.snappy) { showingDatePicker.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.title2)
                        .foregroundStyle(Theme.rust)
                    Text(date.shortDayText)
                        .font(.system(.title3, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    CountPill(text: daysLeft <= 0 ? tr("today", "oggi") : tr("in \(daysLeft) days", "tra \(daysLeft) giorni"))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showingDatePicker {
                DatePicker(tr("Exam date", "Data dell'esame"), selection: $date,
                           in: Calendar.current.startOfDay(for: .now)...,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.rust)
                    .padding(.horizontal, 8)
                    .transition(.opacity)
            }
        }
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var kindPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tr("Type", "Tipo"))
                .font(.dmHeadline)
                .foregroundStyle(Theme.ink)
            HStack(spacing: 8) {
                ForEach(ExamKind.allCases) { option in
                    Button {
                        Haptics.tap()
                        withAnimation(.snappy) { kind = option }
                    } label: {
                        Text(option.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(kind == option ? .white : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(kind == option ? Theme.cocoa : Theme.cream, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(kind.detail)
                .font(.caption)
                .foregroundStyle(Theme.mute)
        }
    }

    private var materials: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("Materials", "Materiale"))
                .font(.dmHeadline)
                .foregroundStyle(Theme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(topics) { topic in
                        Button {
                            editingTopic = topic
                        } label: {
                            VStack(spacing: 1) {
                                Text(topic.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Text(tr("\(topic.pages) p. · \(topic.difficulty.title)",
                                        "\(topic.pages) pag. · \(topic.difficulty.title)"))
                                    .font(.caption2)
                                    .foregroundStyle(Theme.mute)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Theme.cream, in: Capsule())
                            .overlay(Capsule().strokeBorder(.black.opacity(0.06)))
                            .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        nameFocused = false
                        editingTopic = TopicDraft(name: "", pages: 20, difficulty: .medium)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(Theme.rust)
                            .frame(width: 44, height: 44)
                            .overlay(Circle().strokeBorder(Theme.rust, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tr("Add topic", "Aggiungi argomento"))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }

            Text(tr("One chip per topic or chapter, in study order. Tap a chip to change pages and difficulty.",
                    "Una chip per argomento o capitolo, in ordine di studio. Tocca una chip per cambiare pagine e difficoltà."))
                .font(.caption)
                .foregroundStyle(Theme.mute)
        }
    }

    /// 💡 Anteprima LIVE del piano: vedi subito quanto pesa e se ci sta nel tuo tempo.
    private var planCard: some View {
        let estimate = StepGenerator.estimate(topics: topics, kind: kind)
        let perDay = Int((Double(estimate.minutes) / Double(studyDays)).rounded(.up))
        let fits = Double(perDay) <= Double(dailyMinutes) * 1.1

        return VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topics.isEmpty
                         ? tr("Add your topics", "Aggiungi gli argomenti")
                         : tr("\(topics.count) topics · ≈ \(estimate.minutes.asDuration) in total",
                              "\(topics.count) argomenti · ≈ \(estimate.minutes.asDuration) in tutto"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink.opacity(0.8))
                    Text(tr("\(estimate.steps) tiny steps", "\(estimate.steps) piccoli passi"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 90)

                SlothView(pose: .thinking)
                    .frame(width: 90, height: 115)
                    .offset(x: 6, y: -6)
            }

            // La pista va da 0 (🐢) a 1 (🐇). La divido in 7 "scatti", uno per ogni opzione
            // di dailyOptions: trasformo il valore 0…1 nell'indice dell'opzione più vicina.
            TortoiseTrack(value: Double(paceIndex) / Double(dailyOptions.count - 1),
                          dots: dailyOptions.count) { value in
                let index = Int((value * Double(dailyOptions.count - 1)).rounded())
                if index != paceIndex {
                    Haptics.tap()
                    paceIndex = index
                }
            }

            Text(tr("Your pace: \(dailyMinutes.asDuration) a day", "Il tuo ritmo: \(dailyMinutes.asDuration) al giorno"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.cocoa)

            if !topics.isEmpty {
                Divider().overlay(Theme.cocoa.opacity(0.2))
                HStack(alignment: .top, spacing: 8) {
                    Text(fits ? "✅" : "⚠️")
                    Text(fits
                         ? tr("It fits: ≈ \(perDay.asDuration) a day for \(studyDays) days. The plan adapts by itself if you skip a day.",
                              "Ci sta: ≈ \(perDay.asDuration) al giorno per \(studyDays) giorni. Il piano si adatta da solo se salti un giorno.")
                         : tr("It doesn't fit: you'd need \(perDay.asDuration) a day. Go faster on the track, drop less important pages or consider a later date.",
                              "Non ci sta: servirebbero \(perDay.asDuration) al giorno. Sposta la pista verso la lepre, togli pagine meno importanti o valuta l'appello dopo."))
                        .font(.footnote)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .background(Theme.honey, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Theme.honey.opacity(0.35), radius: 10, y: 5)
    }

    // MARK: - Azioni

    /// Salva uno o più argomenti dal foglio (si possono incollare più nomi separati da virgole)
    /// Se l'argomento esiste già (stesso id) lo SOSTITUISCO, altrimenti lo AGGIUNGO in fondo.
    private func saveTopics(_ edited: TopicDraft) {
        let names = StepGenerator.splitTopics(edited.name)
        guard let firstName = names.first else { return }

        if let index = topics.firstIndex(where: { $0.id == edited.id }) {
            // Modifica di un argomento esistente
            topics[index] = TopicDraft(id: edited.id, name: firstName, pages: edited.pages, difficulty: edited.difficulty)
        } else {
            for topicName in names where !topics.contains(where: { $0.name == topicName }) {
                topics.append(TopicDraft(name: topicName, pages: edited.pages, difficulty: edited.difficulty))
            }
        }
    }

    private func save() {
        // guard = "se questa condizione non è vera, esci subito"
        guard canSave else { return }
        let exam = Exam(name: trimmedName, date: date, emoji: "📘", colorIndex: 1,
                        kind: kind, dailyMinutes: dailyMinutes)
        context.insert(exam)
        // Appendendo i passi alla relazione, SwiftData li inserisce automaticamente
        exam.steps.append(contentsOf: StepGenerator.makePlan(topics: topics, kind: kind))

        Haptics.success()
        dismiss()
    }
}

// MARK: - Foglio per un argomento

struct TopicEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var topic: TopicDraft
    let isNew: Bool
    var onSave: (TopicDraft) -> Void
    var onDelete: ((UUID) -> Void)?

    init(topic: TopicDraft, isNew: Bool, onSave: @escaping (TopicDraft) -> Void, onDelete: ((UUID) -> Void)? = nil) {
        _topic = State(initialValue: topic)
        self.isNew = isNew
        self.onSave = onSave
        self.onDelete = onDelete
    }

    private var canSave: Bool {
        !topic.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScreenHeader(eyebrow: tr("Materials", "Materiale"),
                         title: isNew ? tr("New topic", "Nuovo argomento") : tr("Edit topic", "Modifica argomento"))

            TextField(tr("Topic or chapter, e.g. Ch 01", "Argomento o capitolo, es. Cap 01"), text: $topic.name)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Theme.cream, in: Capsule())

            if isNew {
                Text(tr("Tip: paste more names separated by commas to add them all at once.",
                        "Suggerimento: incolla più nomi separati da virgole per aggiungerli tutti insieme."))
                    .font(.caption)
                    .foregroundStyle(Theme.mute)
            }

            Stepper(value: $topic.pages, in: 1...400, step: topic.pages < 10 ? 1 : 5) {
                Label(tr("\(topic.pages) pages", "\(topic.pages) pagine"), systemImage: "doc.text")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
            }

            HStack(spacing: 8) {
                ForEach(Difficulty.allCases) { level in
                    Button {
                        Haptics.tap()
                        topic.difficulty = level
                    } label: {
                        Text(level.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(topic.difficulty == level ? .white : Theme.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(topic.difficulty == level ? Theme.cocoa : Theme.cream, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(tr("≈ \((topic.pages * topic.difficulty.minutesPerPage).asDuration) of reading. Estimates start at 3-7 min per page and adapt to your real speed.",
                    "≈ \((topic.pages * topic.difficulty.minutesPerPage).asDuration) di lettura. Le stime partono da 3-7 min a pagina e si adattano alla tua velocità reale."))
                .font(.caption)
                .foregroundStyle(Theme.mute)

            Spacer(minLength: 0)

            Button(isNew ? tr("Add", "Aggiungi") : tr("Save", "Salva")) {
                onSave(topic)
                Haptics.success()
                dismiss()
            }
            .buttonStyle(PillButtonStyle(variant: .dark))
            .disabled(!canSave)

            if !isNew, let onDelete {
                Button(tr("Remove topic", "Rimuovi argomento"), role: .destructive) {
                    onDelete(topic.id)
                    dismiss()
                }
                .buttonStyle(TextLinkStyle(color: Theme.rust))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(Theme.paper.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        AddExamView()
    }
    .modelContainer(PreviewData.container)
}
