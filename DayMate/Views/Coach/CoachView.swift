//
//  CoachView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Coach": tutto ciò che aiuta a studiare MEGLIO, non solo di più.
//
//   1. 🤖 Tutor AI              → AI on-device se disponibile, altrimenti "Coming soon"
//   2. 💬 Consigli per te       → motore a regole sui tuoi dati (funziona già oggi)
//   3. 💭 Dubbi parcheggiati    → le domande annotate durante i blocchi
//   4. 🔬 Cosa funziona davvero → le tecniche di studio secondo la ricerca
//

import SwiftUI
import SwiftData

struct CoachView: View {
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \Exam.date) private var exams: [Exam]
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @Query(filter: #Predicate<Doubt> { !$0.isResolved }) private var openDoubts: [Doubt]

    /// true = mostrata dentro lo spazio Studio
    var embedded = false
    /// Se c'è, "Dubbi parcheggiati" apre la sezione Dubbi dello spazio invece di una nuova schermata
    var onOpenDoubts: (() -> Void)? = nil

    private var tips: [CoachTip] {
        CoachEngine.tips(exams: exams, sessions: sessions)
    }

    /// Tutti gli argomenti degli esami futuri, per le azioni rapide del tutor
    private var allTopics: [String] {
        exams.filter { !$0.isPast }.flatMap { $0.topics }
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !embedded {
                    TopLink(title: "Home", showsChevron: true)
                    ScreenHeader(eyebrow: tr("Study better, not more", "Studiare meglio, non di più"),
                                 title: "Coach")
                }

                aiCard

                sectionTitle(tr("Tips for you", "Consigli per te"))
                ForEach(tips) { tip in
                    tipCard(tip)
                }

                sectionTitle(tr("Tools", "Strumenti"))
                if let onOpenDoubts {
                    Button(action: onOpenDoubts) { doubtsRow }
                        .buttonStyle(.plain)
                } else {
                    NavigationLink {
                        DoubtsView()
                    } label: {
                        doubtsRow
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    StudyScienceView()
                } label: {
                    toolRow(emoji: "🔬", title: tr("What really works", "Cosa funziona davvero"),
                            subtitle: tr("Study techniques according to research", "Le tecniche di studio secondo la ricerca"),
                            color: Theme.lightMain)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .dmScreen(standalone: !embedded)
    }

    private var doubtsRow: some View {
        toolRow(emoji: "💭", title: tr("Parked doubts", "Dubbi parcheggiati"),
                subtitle: openDoubts.isEmpty
                    ? tr("Write down what you don't understand", "Annota quello che non ti è chiaro")
                    : tr("\(openDoubts.count) to solve", "\(openDoubts.count) da risolvere"),
                color: Theme.lightMain)
    }

    // MARK: - Tutor AI

    @ViewBuilder
    private var aiCard: some View {
        if let chat = AITutor.chatView(topics: allTopics) {
            // ✅ AI disponibile su questo iPhone
            NavigationLink {
                chat
            } label: {
                HStack(spacing: 14) {
                    BlobView(pose: .reading)
                        .frame(width: 64, height: 80)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tr("AI tutor", "Tutor AI"))
                            .font(.system(.title2, weight: .bold))
                            .foregroundStyle(Theme.text)
                        Text(tr("Explanations, exam questions and examples on your topics. Runs on your phone.",
                                "Spiegazioni, domande d'esame ed esempi sui tuoi argomenti. Gira sul telefono."))
                            .font(.subheadline)
                            .foregroundStyle(Theme.text.opacity(0.8))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.text)
                }
                .dmCard(Theme.highlight)
            }
            .buttonStyle(.plain)
        } else {
            // 🚧 AI non ancora disponibile: spiego cosa farà e perché
            AIComingSoonCard(reason: AITutor.unavailableReason)
        }
    }

    // MARK: - Componenti

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.title2, weight: .bold))
            .foregroundStyle(Theme.text)
            .padding(.top, 6)
    }

    private func tipCard(_ tip: CoachTip) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(tip.emoji)
                .font(.title2)
                .frame(width: 46, height: 46)
                .background(tip.color.opacity(0.25), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.dmRowTitle)
                    .foregroundStyle(Theme.text)
                Text(tip.text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .dmCard()
    }

    private func toolRow(emoji: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)
                .frame(width: 46, height: 46)
                .background(color.opacity(0.3), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.dmRowTitle)
                    .foregroundStyle(Theme.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.secondary.opacity(0.6))
        }
        .dmCard()
    }
}

// MARK: - Card "Coming soon"

/// Mostrata quando l'AI non è disponibile: è anche la "roadmap" del progetto.
struct AIComingSoonCard: View {
    let reason: String?

    private struct Feature: Identifiable {
        let id = UUID()
        let emoji: String
        let title: String
        let detail: String
    }

    private let features: [Feature] = [
        Feature(emoji: "💡", title: tr("Tailored explanations", "Spiegazioni su misura"),
                detail: tr("\"Explain it like to a classmate\", with concrete examples.", "\"Spiegamelo come a un compagno\", con esempi concreti.")),
        Feature(emoji: "❓", title: tr("Exam questions", "Domande d'esame"),
                detail: tr("It quizzes you on your topics and corrects you kindly.", "Ti interroga sui tuoi argomenti e ti corregge con gentilezza.")),
        Feature(emoji: "💭", title: tr("Solves your parked doubts", "Risolve i dubbi parcheggiati"),
                detail: tr("The questions noted while studying, picked up at the end.", "Le domande annotate durante lo studio, riprese a fine sessione.")),
        Feature(emoji: "📷", title: tr("From notes to quiz", "Dagli appunti al quiz"),
                detail: tr("Snap a page and it becomes a set of questions (future).", "Fotografi una pagina e diventa una serie di domande (in futuro).")),
        Feature(emoji: "🧭", title: tr("A plan that adapts", "Piano che si adatta"),
                detail: tr("Suggests what to review based on where you go wrong.", "Suggerisce cosa ripassare in base a dove sbagli.")),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                BlobView(pose: .tired)
                    .frame(width: 56, height: 72)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("AI tutor", "Tutor AI"))
                        .font(.system(.title2, weight: .bold))
                        .foregroundStyle(Theme.text)
                    Text(tr("COMING SOON", "IN ARRIVO"))
                        .font(.caption.bold())
                        .tracking(1.2)
                        .foregroundStyle(Theme.lightMain)
                }
                Spacer()
            }

            ForEach(features) { feature in
                HStack(alignment: .top, spacing: 10) {
                    Text(feature.emoji)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(feature.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.text)
                        Text(feature.detail)
                            .font(.caption)
                            .foregroundStyle(Theme.text.opacity(0.75))
                    }
                }
            }

            Divider()

            Label {
                Text(tr("It will run on your phone with the Apple Intelligence model: no server, your data never leaves your iPhone.",
                        "Girerà sul telefono con il modello di Apple Intelligence: niente server, i tuoi dati non escono dall'iPhone."))
                    .font(.caption)
                    .foregroundStyle(Theme.text)
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Theme.accent)
            }

            if let reason {
                Label {
                    Text(reason).font(.caption)
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Theme.lightMain)
                }
                .foregroundStyle(Theme.secondary)
            }
        }
        .dmCard(Theme.highlight)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack {
        CoachView()
    }
    .modelContainer(PreviewData.container)
}
