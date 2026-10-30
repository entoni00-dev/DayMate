//
//  AddExamView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "New exam" (schermata 03 di Sketch):
//
//   Cancel
//   New exam
//   SUBJECT      [ Math              ]
//   EXAM DATE    [ 12 November 2026 📅]
//   TIME PER DAY [ 1 h ]   ✅ Ci sta: ≈ 25 min al giorno per 14 giorni
//   TINY STEPS   ○ Read notes Ch. 1   ≡
//                ○ Exercises 1–5      ≡
//                + Add a tiny step
//   (Blob) Keep steps small: 10–25 minutes each is a good size
//   (In Sketch c'è "works best": l'ho ammorbidito perché non c'è uno studio che
//    dimostri che 10–25 minuti sia la misura migliore per tutti.)
//           [  Save  ]                    ← il grande bottone viola in fondo
//
//  I passi li scrivo io, uno per riga, e li riordino trascinando ≡.
//  Se non so da dove partire c'è "Crea i passi da argomenti e pagine": dico argomenti,
//  pagine e difficoltà e l'app crea un piano realistico con regole semplici
//  (niente intelligenza artificiale: vedi StepGenerator.swift).
//
//  📌 Nota per me: qui uso un Form (la lista "a gruppi" di iOS) perché mi dà gratis
//  il trascinamento per riordinare (.onMove) e lo swipe per eliminare (.onDelete).
//

import SwiftUI
import SwiftData

/// Un passo mentre lo sto scrivendo (non ancora salvato nel database)
struct TinyStepDraft: Identifiable {
    var id = UUID()
    var title: String
    var minutes: Int = 15
    var kind: StepKind = .custom
    var topic: String = ""
}

struct AddExamView: View {
    // dismiss() chiude questa schermata e torna indietro
    @Environment(\.dismiss) private var dismiss
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var subject = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
    @State private var steps: [TinyStepDraft] = []
    @State private var newStep = ""
    /// Quanto tempo al giorno posso dedicare a questo esame (in minuti)
    @State private var dailyMinutes = 60
    @State private var showingGenerator = false
    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var newStepFocused: Bool

    private var trimmedSubject: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// I tempi possibili: dalla tartaruga 🐢 (30 min) alla lepre 🐇 (5 ore)
    private let dailyOptions = [30, 60, 90, 120, 180, 240, 300]

    /// Quanti giorni ho per studiare (da oggi al giorno prima dell'esame, almeno 1)
    private var studyDays: Int {
        let today = Calendar.current.startOfDay(for: .now)
        let examDay = Calendar.current.startOfDay(for: date)
        let days = Calendar.current.dateComponents([.day], from: today, to: examDay).day ?? 0
        return max(1, days)
    }

    /// Quanti minuti al giorno servirebbero per fare tutti i passi in tempo.
    /// reduce = "somma tutti i minuti dei passi"; poi divido per i giorni, arrotondando per eccesso
    private var neededPerDay: Int {
        let total = steps.reduce(0) { $0 + $1.minutes }
        return Int((Double(total) / Double(studyDays)).rounded(.up))
    }

    /// Il piano ci sta nel tempo che ho? (tollero un 10% in più, come StudyPlanner)
    private var planFits: Bool {
        Double(neededPerDay) <= Double(dailyMinutes) * 1.1
    }

    /// Posso salvare solo con un nome e almeno un passo
    private var canSave: Bool {
        !trimmedSubject.isEmpty && !steps.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Riga in alto: solo Cancel (Save è il bottone grande in fondo, come in Sketch)
            HStack {
                TopLink(title: tr("Cancel", "Annulla"))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScreenTitle(title: tr("New exam", "Nuovo esame"), large: false)
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Form {
                Section(tr("Subject", "Materia")) {
                    TextField(tr("e.g. Math", "es. Matematica"), text: $subject)
                        .textInputAutocapitalization(.words)
                }
                .listRowBackground(Theme.card)

                Section(tr("Exam date", "Data dell'esame")) {
                    DatePicker(tr("Date", "Data"), selection: $date,
                               in: Calendar.current.startOfDay(for: .now)...,
                               displayedComponents: .date)
                }
                .listRowBackground(Theme.card)

                // ⏱️ Tempo al giorno + "ci sta?" (c'era nella prima versione di DayMate)
                Section {
                    Picker(tr("Time per day", "Tempo al giorno"), selection: $dailyMinutes) {
                        ForEach(dailyOptions, id: \.self) { minutes in
                            Text(minutes.asDuration).tag(minutes)
                        }
                    }
                    // La card compare solo quando c'è almeno un passo da calcolare
                    if !steps.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Text(planFits ? "✅" : "⚠️")
                            Text(planFits
                                 ? tr("It fits: ≈ \(neededPerDay.asDuration) a day for \(studyDays) days. If you skip a day, the plan adapts by itself.",
                                      "Ci sta: ≈ \(neededPerDay.asDuration) al giorno per \(studyDays) giorni. Se salti un giorno, il piano si adatta da solo.")
                                 : tr("It doesn't fit: you'd need \(neededPerDay.asDuration) a day. Add time, remove less important steps or consider a later exam date.",
                                      "Non ci sta: servirebbero \(neededPerDay.asDuration) al giorno. Aumenta il tempo, togli i passi meno importanti o valuta l'appello dopo."))
                                .font(.footnote)
                                .foregroundStyle(planFits ? Theme.accent : Theme.warning)
                        }
                    }
                } header: {
                    Text(tr("Time per day", "Tempo al giorno"))
                }
                .listRowBackground(Theme.card)

                Section {
                    // I passi: si riordinano trascinando ≡ e si eliminano con il "-" rosso
                    ForEach(steps) { step in
                        HStack(spacing: 12) {
                            CheckCircle(state: .todo)
                            Text(step.title)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Text("\(step.minutes) min")
                                .font(.footnote)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .onMove { from, to in steps.move(fromOffsets: from, toOffset: to) }
                    .onDelete { offsets in steps.remove(atOffsets: offsets) }

                    // L'ultima riga serve per aggiungere un passo
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 24)
                        TextField(tr("Add a tiny step", "Aggiungi un piccolo passo"), text: $newStep)
                            .focused($newStepFocused)
                            .submitLabel(.done)
                            .onSubmit(addStep)
                    }
                } header: {
                    Text(tr("Tiny steps", "Piccoli passi"))
                } footer: {
                    Text(tr("One step = one thing you can do in 10–25 minutes.",
                            "Un passo = una cosa che fai in 10–25 minuti."))
                }
                .listRowBackground(Theme.card)

                Section {
                    Button {
                        showingGenerator = true
                    } label: {
                        Label(tr("Create steps from topics and pages", "Crea i passi da argomenti e pagine"), systemImage: "list.number")
                            .foregroundStyle(Theme.lightMain)
                    }
                } footer: {
                    Text(tr("Tell me topics and pages: I'll build a realistic plan with reading, recall, review and a mock exam.",
                            "Dimmi argomenti e pagine: creo un piano realistico con lettura, ripasso a memoria e simulazione."))
                }
                .listRowBackground(Theme.card)

                Section {
                    HintCard(title: tr("Keep steps small:", "Tieni i passi piccoli:"),
                             text: tr("10–25 minutes each is a good size", "10–25 minuti l'uno è una buona misura"))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)   // tolgo lo sfondo grigio del Form
            // il Form sempre "in modifica": così si vedono le maniglie ≡ per riordinare
            .environment(\.editMode, .constant(.active))
        }
        // .safeAreaInset(edge: .bottom) tiene il bottone sempre visibile in fondo,
        // anche quando la lista scorre
        .safeAreaInset(edge: .bottom) {
            Button(action: save) {
                Text(tr("Save", "Salva"))
                    .font(.system(.title2, weight: .bold))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canSave)          // grigio finché manca il nome o un passo
            .padding(.horizontal, 48)
            .padding(.vertical, 8)
            .background(Theme.background)
        }
        .dmScreen()
        .sheet(isPresented: $showingGenerator) {
            StepGeneratorSheet(defaultTopic: trimmedSubject) { generated in
                steps.append(contentsOf: generated)
            }
        }
    }

    // MARK: - Azioni

    private func addStep() {
        let title = newStep.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        steps.append(TinyStepDraft(title: title))
        newStep = ""
        newStepFocused = true      // la tastiera resta aperta per scrivere il prossimo
        Haptics.tap()
    }

    private func save() {
        // guard = "se questa condizione non è vera, esci subito"
        guard canSave else { return }
        let exam = Exam(name: trimmedSubject, date: date, emoji: "📘", colorIndex: 0,
                        kind: .mixed, dailyMinutes: dailyMinutes)
        context.insert(exam)
        // Trasformo le bozze in passi veri, nell'ordine scelto (enumerated mi dà anche l'indice)
        for (index, draft) in steps.enumerated() {
            let step = StudyStep(title: draft.title,
                                 topic: draft.topic.isEmpty ? trimmedSubject : draft.topic,
                                 minutes: draft.minutes, order: index, kind: draft.kind)
            exam.steps.append(step)   // appendendo alla relazione, SwiftData salva anche il passo
        }
        Haptics.success()
        dismiss()
    }
}

// MARK: - "Crea i passi da argomenti e pagine"

/// Il foglio che usa StepGenerator: argomenti + pagine + difficoltà → passi realistici
struct StepGeneratorSheet: View {
    let defaultTopic: String
    /// Restituisce i passi creati
    var onCreate: ([TinyStepDraft]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var topicsText = ""
    @State private var pages = 20
    @State private var difficulty: Difficulty = .medium
    @State private var kind: ExamKind = .mixed

    /// Gli argomenti scritti separati da virgole ("Limiti, Derivate")
    private var topics: [TopicDraft] {
        StepGenerator.splitTopics(topicsText).map {
            TopicDraft(name: $0, pages: pages, difficulty: difficulty)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(tr("e.g. Limits, Derivatives, Integrals", "es. Limiti, Derivate, Integrali"),
                              text: $topicsText, axis: .vertical)
                } header: {
                    Text(tr("Topics", "Argomenti"))
                } footer: {
                    Text(tr("Separate them with commas, in study order.", "Separali con una virgola, in ordine di studio."))
                }
                .listRowBackground(Theme.card)

                Section(tr("Each topic", "Ogni argomento")) {
                    Stepper(value: $pages, in: 1...400, step: pages < 10 ? 1 : 5) {
                        Text(tr("\(pages) pages", "\(pages) pagine"))
                    }
                    Picker(tr("Difficulty", "Difficoltà"), selection: $difficulty) {
                        ForEach(Difficulty.allCases) { Text($0.title).tag($0) }
                    }
                    Picker(tr("Exam type", "Tipo d'esame"), selection: $kind) {
                        ForEach(ExamKind.allCases) { Text($0.title).tag($0) }
                    }
                }
                .listRowBackground(Theme.card)

                if !topics.isEmpty {
                    let estimate = StepGenerator.estimate(topics: topics, kind: kind)
                    Section {
                        Text(tr("\(estimate.steps) tiny steps · ≈ \(estimate.minutes.asDuration) in total",
                                "\(estimate.steps) piccoli passi · ≈ \(estimate.minutes.asDuration) in tutto"))
                            .foregroundStyle(Theme.accent)
                    }
                    .listRowBackground(Theme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(tr("Create the steps", "Crea i passi"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel", "Annulla")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Add", "Aggiungi")) {
                        // da StepDraft (del generatore) a TinyStepDraft (della schermata)
                        let drafts = StepGenerator.makeDrafts(topics: topics, kind: kind).map {
                            TinyStepDraft(title: $0.title, minutes: $0.minutes, kind: $0.kind, topic: $0.topic)
                        }
                        onCreate(drafts)
                        Haptics.success()
                        dismiss()
                    }
                    .bold()
                    .disabled(topics.isEmpty)
                }
            }
        }
        .onAppear {
            if topicsText.isEmpty { topicsText = defaultTopic }
        }
        .preferredColorScheme(.dark)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        AddExamView()
    }
    .modelContainer(PreviewData.container)
}
