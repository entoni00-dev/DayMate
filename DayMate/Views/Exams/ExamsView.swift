//
//  ExamsView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Your Exams" di Sketch:
//   - la settimana in alto (un puntino sui giorni d'esame)
//   - "+ Add an exam"
//   - l'esame più vicino in grande, color miele, con "▶ Next tiny step"
//   - gli altri esami più piccoli sotto
//
//  "Next tiny step" apre subito la sessione: un tocco tra "voglio studiare" e "sto studiando".
//

import SwiftUI
import SwiftData
import TipKit

struct ExamsView: View {
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \Exam.date) private var exams: [Exam]
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    /// true = mostrata dentro lo spazio Studio (senza "‹ Home" e titolo propri)
    var embedded = false

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var selectedDay = Date()
    /// Se non è nil apro la sessione di studio a schermo intero per questo esame
    @State private var sessionExam: Exam?

    private var upcoming: [Exam] { exams.filter { !$0.isPast } }
    private var past: [Exam] { exams.filter { $0.isPast } }

    /// L'esame "in evidenza": il più vicino con ancora passi da fare
    private var featured: Exam? {
        upcoming.first { $0.remainingCount > 0 } ?? upcoming.first
    }

    private var others: [Exam] {
        upcoming.filter { $0.persistentModelID != featured?.persistentModelID }
    }

    /// Esami nel giorno scelto sulla striscia
    private var examsOnSelectedDay: [Exam] {
        exams.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDay) }
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !embedded {
                    BackPill(title: "Home")

                    Text(tr("Your Exams", "I tuoi esami"))
                        .font(.dmHuge)
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                }

                // 💡 Suggerimento di TipKit (sparisce quando l'utente lo chiude)
                if !exams.isEmpty {
                    TipView(TinyStepTip())
                        .tint(Theme.rust)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedDay.longDayText)
                        .font(.dmSerif)
                        .foregroundStyle(Theme.ink)
                    WeekStrip(selected: $selectedDay, marked: exams.map(\.date))
                    if !examsOnSelectedDay.isEmpty {
                        Label(examsOnSelectedDay.map(\.name).joined(separator: ", "), systemImage: "pin.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.rust)
                    }
                }

                NavigationLink {
                    AddExamView()
                } label: {
                    AddExamRow()
                }
                .buttonStyle(.plain)

                if exams.isEmpty {
                    emptyState
                }

                if let featured {
                    FeaturedExamCard(exam: featured) { sessionExam = featured }
                }

                ForEach(others) { exam in
                    // NavigationLink(value:) apre un'altra schermata; quale, lo decide .navigationDestination
                    NavigationLink(value: exam) {
                        CompactExamRow(exam: exam)
                    }
                    .buttonStyle(.plain)
                    // .contextMenu = il menu che compare tenendo premuto
                    .contextMenu { deleteButton(exam) }
                }

                if !past.isEmpty {
                    Text(tr("Past exams", "Esami passati"))
                        .font(.dmHeadline)
                        .foregroundStyle(Theme.mute)
                        .padding(.top, 8)
                    ForEach(past) { exam in
                        NavigationLink(value: exam) {
                            CompactExamRow(exam: exam)
                        }
                        .buttonStyle(.plain)
                        .opacity(0.6)
                        .contextMenu { deleteButton(exam) }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .dmScreen(standalone: !embedded)
        // La destinazione per Exam è dichiarata in StudyModeView / PlannerModeView
        .fullScreenCover(item: $sessionExam) { exam in
            SessionFlowView(exam: exam)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            SlothView(pose: .thinking)
                .frame(height: 150)
            Text(tr("No exams, for now", "Nessun esame, per ora"))
                .font(.dmTitle2)
                .foregroundStyle(Theme.ink)
            Text(tr("Add your next exam: we'll split it into steps so small that starting will be easy.",
                    "Aggiungi il tuo prossimo esame: lo divideremo in passi così piccoli che iniziare sarà facile."))
                .font(.subheadline)
                .foregroundStyle(Theme.mute)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }

    private func deleteButton(_ exam: Exam) -> some View {
        Button(role: .destructive) {
            // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
            withAnimation { context.delete(exam) }
        } label: {
            Label(tr("Delete exam", "Elimina esame"), systemImage: "trash")
        }
    }
}

// MARK: - "+ Add an exam"

private struct AddExamRow: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "plus")
                .font(.title2.weight(.medium))
                .foregroundStyle(Theme.cocoa)
                .frame(width: 42, height: 42)
                .background(Theme.honey, in: Circle())
            Text(tr("Add an exam", "Aggiungi un esame"))
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.title2.weight(.light))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Theme.cocoa, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
    }
}

// MARK: - L'esame in evidenza (card miele)

struct FeaturedExamCard: View {
    let exam: Exam
    var onNextStep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: exam) {
                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 6) {
                        CountPill(text: exam.countdownPill)
                        Text(exam.name)
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                            .padding(.top, 6)
                            .padding(.trailing, 110)
                        Text(exam.date.shortDayText)
                            .font(.title3)
                            .foregroundStyle(Theme.ink.opacity(0.85))
                        Text(exam.stepsDoneText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.rust)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    SlothView(pose: .pointing)
                        .frame(width: 120, height: 150)
                        .offset(x: 6, y: -4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            TortoiseTrack(value: exam.progress, dots: exam.steps.count)

            if exam.remainingCount > 0 && !exam.isPast {
                Button(action: onNextStep) {
                    Label(tr("Next tiny step", "Prossimo piccolo passo"), systemImage: "play.fill")
                }
                .buttonStyle(PillButtonStyle(variant: .dark, height: 52))
            } else {
                Label(tr("All steps done 🎉", "Tutti i passi fatti 🎉"), systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.cocoa)
            }
        }
        .padding(18)
        .background(Theme.honey, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Theme.honey.opacity(0.4), radius: 12, y: 6)
    }
}

// MARK: - Gli altri esami

struct CompactExamRow: View {
    let exam: Exam

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(exam.name)
                    .font(.dmTitle2)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.mute.opacity(0.6))
            }
            Text(exam.countdownPill)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.rust.opacity(0.8))
            TortoiseTrack(value: exam.progress, dots: exam.steps.count, light: false)
            Divider()
        }
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        ExamsView()
    }
    .modelContainer(PreviewData.container)
}
