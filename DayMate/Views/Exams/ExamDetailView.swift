//
//  ExamDetailView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Dettaglio di un esame (stile DayMate):
//   1. card miele con countdown, passi fatti e pista 🐢→🐇
//   2. 📅 PIANO DI OGGI: i passi di oggi + il programma studio/pause
//   3. le 3 fasi del piano (studio → ripasso → simulazione)
//   4. tutti i passi, raggruppati per argomento
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
    // dismiss() chiude questa schermata (o il foglio) e torna indietro
    @Environment(\.dismiss) private var dismiss

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var showingSession = false
    @State private var confirmDelete = false
    @State private var showingAddTopic = false
    @State private var showingAllDays = false
    @State private var showingAddDoubt = false

    private let dailyOptions = [30, 60, 90, 120, 180, 240, 300]

    /// Il piano viene ricalcolato a ogni ridisegno: è veloce e sempre aggiornato
    private var plan: StudyPlan { StudyPlanner.plan(for: exam) }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    BackPill(title: tr("Exams", "Esami"))
                    Spacer()
                    optionsMenu
                }

                header

                if exam.isPast {
                    infoCard(emoji: "📌", title: tr("Exam passed", "Esame passato"),
                             text: tr("How did it go? You can delete it from the ••• menu or keep it for your history.",
                                      "Com'è andata? Puoi eliminarlo dal menu ••• o tenerlo per lo storico."))
                } else if exam.remainingCount == 0 && !exam.steps.isEmpty {
                    infoCard(emoji: "🏆", title: tr("Plan completed!", "Piano completato!"),
                             text: tr("You did every step, one at a time. Now sleep well the night before: that counts too.",
                                      "Hai fatto tutti i passi, uno alla volta. Ora dormi bene la notte prima: conta anche quello."))
                } else {
                    todayCard
                    if !plan.fits { planWarning }
                    upcomingDays
                }

                phasesCard

                ForEach(exam.topics, id: \.self) { topic in
                    topicSection(title: topic, steps: exam.topicSteps(topic))
                }
                if !exam.phaseSteps(.review).isEmpty {
                    topicSection(title: "🔁 " + StudyPhase.review.title, steps: exam.phaseSteps(.review))
                }
                if !exam.phaseSteps(.simulate).isEmpty {
                    topicSection(title: "🎯 " + StudyPhase.simulate.title, steps: exam.phaseSteps(.simulate))
                }

                Button {
                    showingAddTopic = true
                } label: {
                    Label(tr("Add topic", "Aggiungi argomento"), systemImage: "plus")
                }
                .buttonStyle(PillButtonStyle(variant: .cream, height: 50))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
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
        .sheet(isPresented: $showingAddTopic) {
            TopicEditorSheet(topic: TopicDraft(name: "", pages: 20, difficulty: .medium),
                             isNew: true,
                             onSave: addTopics)
        }
        .sheet(isPresented: $showingAddDoubt) {
            AddDoubtSheet(preselectedExam: exam.name)
        }
        // .fullScreenCover = una schermata che copre tutto (la uso per la sessione di studio)
        .fullScreenCover(isPresented: $showingSession) {
            SessionFlowView(exam: exam)
        }
    }

    // MARK: - Menu •••

    private var optionsMenu: some View {
        Menu {
            Picker(tr("Time per day", "Tempo al giorno"), selection: Binding(
                get: { exam.dailyMinutes },
                set: { exam.dailyMinutes = $0 }
            )) {
                ForEach(dailyOptions, id: \.self) { minutes in
                    Text(tr("\(minutes.asDuration) a day", "\(minutes.asDuration) al giorno")).tag(minutes)
                }
            }
            Button {
                showingAddDoubt = true
            } label: {
                Label(tr("Add a doubt", "Aggiungi un dubbio"), systemImage: "bubble.left.and.exclamationmark.bubble.right")
            }
            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label(tr("Delete exam", "Elimina esame"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.rust)
                .frame(width: 44, height: 44)
                .background(Theme.pillGray, in: Circle())
        }
        .accessibilityLabel(tr("Options", "Opzioni"))
    }

    // MARK: - Intestazione (card miele)

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 6) {
                    CountPill(text: exam.countdownPill)
                    Text(exam.name)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .padding(.trailing, 100)
                    Text(exam.date.shortDayText)
                        .font(.title3)
                        .foregroundStyle(Theme.ink.opacity(0.85))
                    Text(exam.stepsDoneText + " · " + tr("≈ \(exam.remainingMinutes.asDuration) left",
                                                         "mancano ≈ \(exam.remainingMinutes.asDuration)"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.rust)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SlothView(pose: .pointing)
                    .frame(width: 104, height: 130)
                    .offset(x: 6)
            }
            TortoiseTrack(value: exam.progress, dots: exam.steps.count)
        }
        .padding(18)
        .background(Theme.honey, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Theme.honey.opacity(0.4), radius: 12, y: 6)
    }

    // MARK: - 📅 Piano di oggi

    @ViewBuilder
    private var todayCard: some View {
        if let today = plan.today {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(tr("TODAY", "OGGI"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Theme.rust)
                    Spacer()
                    Text(today.isComplete
                         ? tr("Done! 🎉", "Fatto! 🎉")
                         : tr("\(today.remainingSteps) steps · \(today.remainingMinutes.asDuration)",
                              "\(today.remainingSteps) passi · \(today.remainingMinutes.asDuration)"))
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.ink)
                }

                if today.isComplete {
                    Text(tr("You finished today's plan. You can stop with a clear conscience, or keep going: tomorrow's steps will get shorter.",
                            "Hai finito il piano di oggi. Puoi fermarti con la coscienza pulita, oppure andare avanti: i passi di domani si accorceranno."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.mute)
                } else {
                    DayScheduleView(studyMinutes: today.remainingMinutes)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(today.steps) { step in
                        stepRow(step)
                    }
                }

                Button {
                    showingSession = true
                } label: {
                    Label(today.isComplete ? tr("Keep going anyway", "Vai avanti lo stesso")
                                           : tr("Next tiny step", "Prossimo piccolo passo"),
                          systemImage: "play.fill")
                }
                .buttonStyle(PillButtonStyle(variant: .dark, height: 52))
            }
            .dmCard()
        }
    }

    private var planWarning: some View {
        infoCard(emoji: "⚠️", title: tr("The plan is tight", "Il piano è stretto"),
                 text: tr("You'd need about \(plan.neededPerDay.asDuration) a day, but you set \(exam.dailyMinutes.asDuration). You can change your daily time from the ••• menu. Better to know today than the week before.",
                          "Servirebbero circa \(plan.neededPerDay.asDuration) al giorno, ma ne hai indicati \(exam.dailyMinutes.asDuration). Puoi cambiare il tempo giornaliero dal menu •••. Meglio saperlo oggi che la settimana prima."))
    }

    /// I prossimi giorni, in forma compatta
    @ViewBuilder
    private var upcomingDays: some View {
        let next = plan.days.filter { !$0.isToday }
        if !next.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation(.snappy) { showingAllDays.toggle() }
                } label: {
                    HStack {
                        Text(tr("Next days", "Prossimi giorni"))
                            .font(.dmHeadline)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Theme.mute)
                            .rotationEffect(.degrees(showingAllDays ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                ForEach(showingAllDays ? next : Array(next.prefix(3))) { day in
                    HStack {
                        Text(day.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(L10n.locale)))
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 110, alignment: .leading)
                        Text(day.steps.first.map { $0.kind.emoji + " " + $0.topic } ?? "")
                            .font(.caption)
                            .foregroundStyle(Theme.mute)
                            .lineLimit(1)
                        Spacer()
                        Text(day.minutes.asDuration)
                            .font(.caption.bold())
                            .foregroundStyle(Theme.rust)
                    }
                }

                if !showingAllDays && next.count > 3 {
                    Text(tr("+ \(next.count - 3) more days", "+ altri \(next.count - 3) giorni"))
                        .font(.caption)
                        .foregroundStyle(Theme.mute)
                }

                Text(tr("The plan is recalculated every day: if you skip a day, the work spreads out by itself.",
                        "Il piano si ricalcola ogni giorno: se salti un giorno, il lavoro si ridistribuisce da solo."))
                    .font(.caption2)
                    .foregroundStyle(Theme.mute)
            }
            .dmCard()
        }
    }

    // MARK: - Le 3 fasi

    private var phasesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("Plan phases", "Le fasi del piano"))
                .font(.dmHeadline)
                .foregroundStyle(Theme.ink)

            ForEach(StudyPhase.allCases) { phase in
                let steps = exam.phaseSteps(phase)
                if !steps.isEmpty {
                    let done = steps.filter { $0.isDone }.count
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(phase.emoji) \(phase.title)")
                                .font(.subheadline.bold())
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text("\(done)/\(steps.count)")
                                .font(.caption.bold())
                                .foregroundStyle(Theme.rust)
                        }
                        ProgressView(value: Double(done), total: Double(steps.count))
                            .tint(Theme.honey)
                        Text(phase.detail)
                            .font(.caption)
                            .foregroundStyle(Theme.mute)
                    }
                }
            }
        }
        .dmCard()
    }

    // MARK: - Argomento

    private func topicSection(title: String, steps: [StudyStep]) -> some View {
        let done = steps.filter { $0.isDone }.count

        return DisclosureGroup {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(steps) { step in
                    stepRow(step)
                }
            }
            .padding(.top, 10)
        } label: {
            HStack {
                Text(title)
                    .font(.dmHeadline)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(done)/\(steps.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.rust)
            }
        }
        .tint(Theme.mute)
        .dmCard()
    }

    private func stepRow(_ step: StudyStep) -> some View {
        Button {
            withAnimation(.snappy) {
                step.isDone.toggle()
                step.completedAt = step.isDone ? .now : nil
            }
            if step.isDone { Haptics.tap() }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                SquareCheck(isOn: step.isDone, tint: Theme.cocoa)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(.subheadline)
                        .strikethrough(step.isDone)
                        .foregroundStyle(step.isDone ? Theme.mute : Theme.ink)
                        .multilineTextAlignment(.leading)
                    Text("\(step.kind.emoji) \(step.kind.label) · ≈ \(exam.estimatedMinutes(for: step)) min")
                        .font(.caption)
                        .foregroundStyle(Theme.mute)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoCard(emoji: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(emoji).font(.title)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.dmHeadline)
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.mute)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dmCard()
    }

    // MARK: - Azioni

    /// Aggiunge uno o più argomenti (nomi separati da virgole) in fondo alla fase di studio
    private func addTopics(_ draft: TopicDraft) {
        for name in StepGenerator.splitTopics(draft.name) {
            let topic = TopicDraft(name: name, pages: draft.pages, difficulty: draft.difficulty)
            // Continuo la numerazione: grazie all'ordinamento per fase, i passi di studio
            // finiscono prima del ripasso e il ripasso prima della simulazione.
            let nextOrder = (exam.steps.map { $0.order }.max() ?? -1) + 1
            exam.steps.append(contentsOf: StepGenerator.makeLearningSteps(for: topic, kind: exam.kind, startingAt: nextOrder))
        }
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
