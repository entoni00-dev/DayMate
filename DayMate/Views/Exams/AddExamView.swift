//
//  AddExamView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "New exam" (schermata 03 di Sketch):
//
//   Cancel                            Save
//   New exam
//   SUBJECT      [ Math              ]
//   EXAM DATE    [ 12 November 2026 📅]
//   TINY STEPS   ○ Read notes Ch. 1   ≡
//                ○ Exercises 1–5      ≡
//                + Add a tiny step
//   (Blob) Keep steps small: 10–25 minutes each works best
//
//  I passi li scrivo io, uno per riga, e li riordino trascinando ≡.
//  Se non so da dove partire c'è "✨ Create the steps for me": dico argomenti, pagine e
//  difficoltà e l'app crea un piano realistico (vedi StepGenerator.swift).
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
    @State private var showingGenerator = false
    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var newStepFocused: Bool

    private var trimmedSubject: String {
        subject.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Posso salvare solo con un nome e almeno un passo
    private var canSave: Bool {
        !trimmedSubject.isEmpty && !steps.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Riga in alto: Cancel a sinistra, Save a destra
            HStack {
                TopLink(title: tr("Cancel", "Annulla"))
                Spacer()
                TopLink(title: tr("Save", "Salva"), bold: true,
                        color: canSave ? Theme.main : Theme.secondary.opacity(0.5),
                        action: save)
                    .disabled(!canSave)
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
                        Label(tr("Create the steps for me", "Crea i passi per me"), systemImage: "sparkles")
                            .foregroundStyle(Theme.lightMain)
                    }
                } footer: {
                    Text(tr("Tell me topics and pages: I'll build a realistic plan with reading, recall, review and a mock exam.",
                            "Dimmi argomenti e pagine: creo un piano realistico con lettura, ripasso a memoria e simulazione."))
                }
                .listRowBackground(Theme.card)

                Section {
                    HintCard(title: tr("Keep steps small:", "Tieni i passi piccoli:"),
                             text: tr("10–25 minutes each works best", "10–25 minuti l'uno funziona meglio"))
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)   // tolgo lo sfondo grigio del Form
            // il Form sempre "in modifica": così si vedono le maniglie ≡ per riordinare
            .environment(\.editMode, .constant(.active))
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
                        kind: .mixed, dailyMinutes: 60)
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

// MARK: - "✨ Crea i passi per me"

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
