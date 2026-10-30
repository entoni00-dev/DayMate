//
//  ExamDetailView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il dettaglio di un esame (schermata 02 di Sketch):
//
//   ‹ Today                                  •••
//   Math
//   Exam on 12 November · in 14 days
//   ┌ (50%)  3 of 6 steps done ─────────────┐
//   │        Keep it tiny, one at a time     │
//   └────────────────────────────────────────┘
//   TINY STEPS   ✓ Read notes Ch. 1
//                ◉ Read Ch. 2            next
//                ○ Exercises 6–10
//   [ Start next step ]
//
//  Nota tecnica: `exam` è una classe @Model. Con il framework Observation (iOS 17)
//  SwiftUI osserva automaticamente le proprietà lette nel body: se cambio
//  step.isDone la vista si aggiorna da sola, senza @ObservedObject.
//

import SwiftUI
import SwiftData

struct ExamDetailView: View {
    let exam: Exam

    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context
    // dismiss() chiude questa schermata e torna indietro
    @Environment(\.dismiss) private var dismiss

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var showingSession = false
    @State private var confirmDelete = false
    @State private var showingAddDoubt = false
    @State private var newStepTitle = ""
    @FocusState private var newStepFocused: Bool

    private let dailyOptions = [30, 60, 90, 120, 180, 240, 300]

    /// Il piano viene ricalcolato a ogni ridisegno: è veloce e sempre aggiornato
    private var plan: StudyPlan { StudyPlanner.plan(for: exam) }

    /// "Exam on 12 November · in 14 days"
    private var subtitle: String {
        let date = exam.date.formatted(.dateTime.day().month(.wide).locale(L10n.locale))
        return tr("Exam on \(date) · \(exam.countdownPill)", "Esame il \(date) · \(exam.countdownPill)")
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    TopLink(title: tr("Today", "Oggi"), showsChevron: true)
                    Spacer()
                    optionsMenu
                }

                ScreenTitle(title: exam.name, subtitle: subtitle)

                progressCard

                if !exam.isPast && !plan.fits {
                    HintCard(title: tr("The plan is tight", "Il piano è stretto"),
                             text: tr("You'd need about \(plan.neededPerDay.asDuration) a day. You can change your daily time from the ••• menu.",
                                      "Servirebbero circa \(plan.neededPerDay.asDuration) al giorno. Puoi cambiare il tempo giornaliero dal menu •••."),
                             pose: .stressed)
                }

                SectionHeader(text: tr("Tiny steps", "Piccoli passi"))
                stepsList
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        // Il bottone resta sempre in fondo, anche scorrendo
        .safeAreaInset(edge: .bottom) {
            if exam.remainingCount > 0 && !exam.isPast {
                Button(tr("Start next step", "Inizia il prossimo passo")) {
                    showingSession = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .background(Theme.background)
            }
        }
        .dmScreen()
        // .confirmationDialog chiede conferma prima di un'azione che non si può annullare
        .confirmationDialog(tr("Delete \(exam.name)?", "Eliminare \(exam.name)?"),
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(tr("Delete", "Elimina"), role: .destructive) { deleteExam() }
        } message: {
            Text(tr("The steps will be deleted. Your sessions stay in Progress.",
                    "I passi verranno eliminati. Le sessioni restano nei Progressi."))
        }
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAddDoubt) {
            AddDoubtSheet(preselectedExam: exam.name)
        }
        // .fullScreenCover = una schermata che copre tutto (la sessione di studio)
        .fullScreenCover(isPresented: $showingSession) {
            SessionFlowView(exam: exam)
        }
    }

    // MARK: - Menu •••

    private var optionsMenu: some View {
        Menu {
            Button {
                showingAddDoubt = true
            } label: {
                Label(tr("Add a doubt", "Aggiungi un dubbio"), systemImage: "questionmark.bubble")
            }
            // Quanto tempo al giorno posso dedicare a questo esame (serve al piano)
            Picker(tr("Time per day", "Tempo al giorno"), selection: Binding(
                get: { exam.dailyMinutes },
                set: { exam.dailyMinutes = $0 }
            )) {
                ForEach(dailyOptions, id: \.self) { minutes in
                    Text(tr("\(minutes.asDuration) a day", "\(minutes.asDuration) al giorno")).tag(minutes)
                }
            }
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label(tr("Delete exam", "Elimina esame"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.headline)
                .foregroundStyle(Theme.lightMain)
                .frame(width: 38, height: 38)
                .background(Theme.card, in: Circle())
        }
        .accessibilityLabel(tr("Options", "Opzioni"))
    }

    // MARK: - La card con l'anello

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRingView(progress: exam.progress, lineWidth: 8)
                Text("\(Int((exam.progress * 100).rounded()))%")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(tr("\(exam.doneCount) of \(exam.steps.count) steps done",
                        "\(exam.doneCount) di \(exam.steps.count) passi fatti"))
                    .font(.system(.headline, weight: .bold))
                    .foregroundStyle(Theme.text)
                Text(exam.remainingCount == 0
                     ? tr("All done. Sleep well the night before!", "Tutto fatto. Dormi bene la notte prima!")
                     : tr("Keep it tiny, one at a time", "Piccoli passi, uno alla volta"))
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .cardBackground(radius: 22)
    }

    // MARK: - TINY STEPS

    private var stepsList: some View {
        let steps = exam.sortedSteps
        let next = exam.nextStep

        return VStack(spacing: 0) {
            ForEach(steps) { step in
                stepRow(step, isNext: step.persistentModelID == next?.persistentModelID)
                RowDivider()
            }

            // Ultima riga: aggiungo un passo scritto da me
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 40)
                TextField(tr("Add a tiny step", "Aggiungi un piccolo passo"), text: $newStepTitle)
                    .font(.system(.callout, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .focused($newStepFocused)
                    .submitLabel(.done)
                    .onSubmit(addStep)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .cardBackground(radius: 18)
    }

    private func stepRow(_ step: StudyStep, isNext: Bool) -> some View {
        Button {
            // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
            withAnimation(.snappy) {
                step.isDone.toggle()
                step.completedAt = step.isDone ? .now : nil
            }
            if step.isDone { Haptics.tap() }
        } label: {
            HStack(spacing: 14) {
                CheckCircle(state: step.isDone ? .done : (isNext ? .next : .todo))
                    .frame(width: 40)
                Text(step.title)
                    .font(.system(.callout, weight: isNext ? .bold : .medium))
                    .foregroundStyle(step.isDone ? Theme.secondary : Theme.text)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if isNext {
                    Text(tr("next", "prossimo"))
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.accent)
                } else if !step.isDone {
                    Text("\(exam.estimatedMinutes(for: step)) min")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // .contextMenu = il menu che compare tenendo premuto
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { context.delete(step) }
            } label: {
                Label(tr("Delete step", "Elimina passo"), systemImage: "trash")
            }
        }
    }

    // MARK: - Azioni

    /// Aggiunge in fondo un passo scritto a mano (15 minuti di default)
    private func addStep() {
        let title = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        // il nuovo passo va dopo tutti gli altri: prendo l'ordine più alto e aggiungo 1
        let nextOrder = (exam.steps.map { $0.order }.max() ?? -1) + 1
        exam.steps.append(StudyStep(title: title, topic: exam.name, minutes: 15, order: nextOrder, kind: .custom))
        newStepTitle = ""
        newStepFocused = true
        Haptics.tap()
    }

    private func deleteExam() {
        // 🐛 Se elimino l'esame mentre questa vista è a schermo, SwiftUI potrebbe
        // leggere un oggetto già cancellato (crash). Prima torno indietro, poi elimino.
        let examToDelete = exam
        let modelContext = context
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            modelContext.delete(examToDelete)
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        ExamDetailView(exam: PreviewData.sampleExam)
    }
    .modelContainer(PreviewData.container)
}
