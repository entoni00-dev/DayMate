//
//  TodayView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Today" (schermata 01 di Sketch) — la prima sezione della modalità Studio.
//
//   ┌ NEXT TINY STEP ───────────────┐
//   │ Read Ch. 2               (Blob)│   ← il passo più vicino: un tocco e si parte
//   │ Math · step 3 of 6             │
//   │ [▶ Start · 15 min]             │
//   └────────────────────────────────┘
//   YOUR EXAMS   Math · Physics …       ← tocco un esame per il dettaglio
//   PLAN         passi di oggi, impegni, acqua   ← collegato al Planner!
//

import SwiftUI
import SwiftData
import TipKit

struct TodayView: View {
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \Exam.date) private var exams: [Exam]
    @Query(sort: \PlannerTask.createdAt) private var tasks: [PlannerTask]
    @Query private var waterLogs: [WaterLog]
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    /// Cosa fare quando non ci sono esami e l'utente tocca "Aggiungi"
    var onAddExam: () -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var sessionExam: Exam?

    private var calendar: Calendar { .current }

    /// L'esame più vicino con ancora passi da fare: da qui viene il "NEXT TINY STEP"
    private var nextExam: Exam? {
        exams.first { !$0.isPast && $0.remainingCount > 0 }
    }

    private var upcoming: [Exam] { exams.filter { !$0.isPast } }

    /// Le attività del Planner di oggi, in ordine di orario
    private var todayTasks: [PlannerTask] {
        tasks.filter { calendar.isDateInToday($0.day) }
            .sorted { ($0.time ?? .distantFuture) < ($1.time ?? .distantFuture) }
    }

    /// I passi di studio che il piano prevede per oggi (tutti gli esami)
    private var todayStudySteps: [StudyStep] {
        upcoming.flatMap { StudyPlanner.plan(for: $0).today?.steps ?? [] }
    }

    private var glasses: Int {
        waterLogs.first { calendar.isDateInToday($0.day) }?.glasses ?? 0
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                nextStepCard

                // 💡 Suggerimento di TipKit (sparisce quando l'utente lo chiude)
                if nextExam != nil {
                    TipView(TinyStepTip())
                        .tint(Theme.main)
                }

                if !exams.isEmpty {
                    SectionHeader(text: tr("Your exams", "I tuoi esami"))
                    examsList
                }

                SectionHeader(text: tr("Plan", "Piano di oggi"))
                planList
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        // .fullScreenCover = una schermata che copre tutto (la sessione di studio)
        .fullScreenCover(item: $sessionExam) { exam in
            SessionFlowView(exam: exam)
        }
    }

    // MARK: - NEXT TINY STEP

    @ViewBuilder
    private var nextStepCard: some View {
        if let exam = nextExam, let step = exam.nextStep {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr("NEXT TINY STEP", "PROSSIMO PICCOLO PASSO"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.accent)
                    Text(step.title)
                        .font(.dmCardTitle)
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                        .padding(.trailing, 70)
                    Text("\(exam.name) · " + tr("step \(exam.doneCount + 1) of \(exam.steps.count)",
                                                "passo \(exam.doneCount + 1) di \(exam.steps.count)"))
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondary)

                    Button {
                        sessionExam = exam
                    } label: {
                        Label(tr("Start · \(exam.estimatedMinutes(for: step)) min",
                                 "Inizia · \(exam.estimatedMinutes(for: step)) min"),
                              systemImage: "play.fill")
                    }
                    .buttonStyle(SmallButtonStyle())
                    .padding(.top, 14)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                BlobView(pose: .reading)
                    .frame(width: 64, height: 64)
            }
            .padding(20)
            .cardBackground(highlighted: true, radius: 22)
        } else {
            // Nessun passo da fare: o non ci sono esami, o è tutto fatto
            HStack(spacing: 14) {
                BlobView(pose: exams.isEmpty ? .hello : .cheer)
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 6) {
                    Text(exams.isEmpty ? tr("Add your first exam", "Aggiungi il primo esame")
                                       : tr("All caught up!", "Tutto fatto!"))
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Text(exams.isEmpty
                         ? tr("We'll split it into tiny steps, so starting is easy.",
                              "Lo divideremo in piccoli passi, così iniziare è facile.")
                         : tr("No steps left. Rest, you earned it.", "Nessun passo rimasto. Riposati, te lo sei meritato."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondary)
                    if exams.isEmpty {
                        Button(tr("New exam", "Nuovo esame"), action: onAddExam)
                            .buttonStyle(SmallButtonStyle())
                            .padding(.top, 4)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(20)
            .cardBackground(highlighted: true, radius: 22)
        }
    }

    // MARK: - YOUR EXAMS

    private var examsList: some View {
        VStack(spacing: 0) {
            ForEach(exams) { exam in
                // NavigationLink(value:) apre un'altra schermata; quale, lo decide .navigationDestination
                NavigationLink(value: exam) {
                    HStack(spacing: 14) {
                        IconTile(systemName: "book")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exam.name)
                                .font(.dmRowTitle)
                                .foregroundStyle(Theme.text)
                            Text(exam.date.formatted(.dateTime.day().month(.abbreviated).locale(L10n.locale))
                                 + " · " + tr("\(exam.doneCount) of \(exam.steps.count) steps",
                                              "\(exam.doneCount) di \(exam.steps.count) passi"))
                                .font(.footnote)
                                .foregroundStyle(Theme.secondary)
                        }
                        Spacer()
                        ProgressRingView(progress: exam.progress, lineWidth: 4)
                            .frame(width: 28, height: 28)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                    .opacity(exam.isPast ? 0.5 : 1)   // gli esami passati un po' spenti
                }
                .buttonStyle(.plain)

                if exam != exams.last {
                    RowDivider()
                }
            }
        }
        .cardBackground(radius: 18)
    }

    // MARK: - PLAN (collegato al Planner)

    private var planList: some View {
        VStack(spacing: 0) {
            // 1. i passi di studio di oggi
            ForEach(todayStudySteps) { step in
                planRow(done: step.isDone,
                        title: "\(step.exam?.name ?? "") · \(step.title)",
                        trailing: step.isDone ? tr("done", "fatto") : "\(step.minutes) min") {
                    step.isDone.toggle()
                    step.completedAt = step.isDone ? .now : nil
                }
                RowDivider()
            }

            // 2. le attività del Planner
            ForEach(todayTasks) { task in
                planRow(done: task.isDone, title: task.title,
                        trailing: task.isDone ? tr("done", "fatto") : task.timeText) {
                    task.isDone.toggle()
                }
                RowDivider()
            }

            // 3. l'acqua: tocco la riga e aggiungo un bicchiere
            planRow(done: glasses >= AppSettings.waterGoal,
                    title: tr("Water · \(glasses) of \(AppSettings.waterGoal)", "Acqua · \(glasses) di \(AppSettings.waterGoal)"),
                    trailing: "+1") {
                addGlass()
            }
        }
        .cardBackground(radius: 18)
    }

    /// Una riga del piano: cerchio, titolo, testo a destra. Tocco = segno fatto.
    private func planRow(done: Bool, title: String, trailing: String, action: @escaping () -> Void) -> some View {
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

    private func addGlass() {
        if let log = waterLogs.first(where: { calendar.isDateInToday($0.day) }) {
            log.glasses = min(log.glasses + 1, AppSettings.waterGoal)
        } else {
            context.insert(WaterLog(day: .now, glasses: 1))
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        TodayView(onAddExam: {})
            .background(Theme.background)
    }
    .modelContainer(PreviewData.container)
}
