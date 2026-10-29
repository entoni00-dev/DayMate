//
//  StatsView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Schermata "Progress".
//  (L'ho chiamata StatsView e non ProgressView perché ProgressView esiste già in SwiftUI!)
//
//  🎯 Cosa misuro e perché:
//  - "Volte che hai iniziato" come numero PRINCIPALE, non le ore.
//    L'app lavora sull'iniziare: è quello che voglio rinforzare.
//  - Giorni attivi invece di "streak": le streak si rompono e quando si rompono
//    fanno sentire in colpa (proprio il circolo vizioso che voglio evitare).
//  - Umore prima/dopo: la prova che iniziare abbassa l'ansia.
//

import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @Query private var steps: [StudyStep]

    /// true = mostrata dentro lo spazio Studio
    var embedded = false

    // MARK: - Dati calcolati

    private var totalFocusMinutes: Int {
        sessions.reduce(0) { $0 + $1.focusedSeconds } / 60
    }

    private var completedSteps: Int {
        steps.filter { $0.isDone }.count
    }

    private var realBreaks: Int {
        sessions.reduce(0) { $0 + $1.realBreaks }
    }

    /// Giorni distinti in cui ho fatto almeno una sessione
    private var activeDays: Int {
        Set(sessions.map { Calendar.current.startOfDay(for: $0.startedAt) }).count
    }

    /// (sessioni in cui l'umore è migliorato, sessioni con check-out)
    private var moodStats: (improved: Int, total: Int) {
        let rated = sessions.compactMap { $0.improved }
        return (rated.filter { $0 }.count, rated.count)
    }

    /// Minuti per ognuno degli ultimi 7 giorni (per il grafico)
    private var weekData: [DayMinutes] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let seconds = sessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.focusedSeconds }
            return DayMinutes(day: day, minutes: Double(seconds) / 60)
        }
    }

    // MARK: - Body

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !embedded {
                    BackPill(title: "Home")
                    ScreenHeader(eyebrow: tr("Slowly but surely", "Piano ma sicuro"),
                                 title: tr("Your progress", "I tuoi progressi"))
                }

                heroCard

                // LazyVGrid = una griglia (qui 2 colonne)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                    StatTile(emoji: "⏱️", value: "\(totalFocusMinutes)", label: tr("minutes of study", "minuti di studio"))
                    StatTile(emoji: "✅", value: "\(completedSteps)", label: tr("tiny steps done", "piccoli passi fatti"))
                    StatTile(emoji: "🚶", value: "\(realBreaks)", label: tr("breaks without phone", "pause senza telefono"))
                    StatTile(emoji: "📅", value: "\(activeDays)", label: tr("days you started", "giorni in cui hai iniziato"))
                }

                weekChart

                if moodStats.total > 0 {
                    moodCard
                }

                if !sessions.isEmpty {
                    recentSessions
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .dmScreen(standalone: !embedded)
    }

    // MARK: - Sezioni

    private var heroCard: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(tr("You started", "Hai iniziato"))
                    .font(.headline)
                    .foregroundStyle(Theme.ink.opacity(0.85))
                Text(sessions.count == 1 ? tr("1 time", "1 volta") : tr("\(sessions.count) times", "\(sessions.count) volte"))
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                Text(sessions.isEmpty
                     ? tr("The first time is the hardest. 2 minutes are enough.", "La prima volta è la più difficile. Bastano 2 minuti.")
                     : tr("Starting is the hard part, and you did it.", "Iniziare è la parte difficile, e tu l'hai fatto."))
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink.opacity(0.85))
                    .padding(.trailing, 90)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SlothView(pose: .great)
                .frame(width: 80, height: 80)
        }
        .padding(20)
        .background(Theme.honey, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.honey.opacity(0.35), radius: 10, y: 5)
    }

    private var weekChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("Last 7 days", "Ultimi 7 giorni"))
                .font(.dmHeadline)
                .foregroundStyle(Theme.ink)

            Chart(weekData) { item in
                BarMark(
                    x: .value("Day", item.day, unit: .day),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(Theme.honey)
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow).locale(L10n.locale))
                }
            }
            .frame(height: 170)
        }
        .dmCard()
    }

    private var moodCard: some View {
        let stats = moodStats
        let percent = Int((Double(stats.improved) / Double(stats.total) * 100).rounded())

        return HStack(alignment: .top, spacing: 14) {
            Text("💚").font(.largeTitle)
            VStack(alignment: .leading, spacing: 4) {
                Text(tr("Starting is good for you", "Iniziare ti fa bene"))
                    .font(.dmHeadline)
                    .foregroundStyle(Theme.ink)
                Text(tr("In \(percent)% of sessions (\(stats.improved) of \(stats.total)) you felt better at the end than when you started.",
                        "Nel \(percent)% delle sessioni (\(stats.improved) su \(stats.total)) alla fine ti sentivi meglio di quando hai iniziato."))
                    .font(.subheadline)
                    .foregroundStyle(Theme.mute)
            }
            Spacer(minLength: 0)
        }
        .dmCard(Theme.cream)
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("Recent sessions", "Sessioni recenti"))
                .font(.dmHeadline)
                .foregroundStyle(Theme.ink)

            ForEach(sessions.prefix(5)) { session in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.exam?.name ?? tr("Deleted exam", "Esame eliminato"))
                            .font(.subheadline.bold())
                            .foregroundStyle(Theme.ink)
                        Text(session.startedAt.formatted(.relative(presentation: .named).locale(L10n.locale)))
                            .font(.caption)
                            .foregroundStyle(Theme.mute)
                    }
                    Spacer()
                    Text("\(session.moodBefore.emoji) → \(session.moodAfter?.emoji ?? "–")")
                    Text("\(session.focusedSeconds / 60)′")
                        .font(.subheadline.bold())
                        .foregroundStyle(Theme.rust)
                        .frame(minWidth: 34, alignment: .trailing)
                }
            }
        }
        .dmCard()
    }
}

/// Un punto del grafico settimanale
struct DayMinutes: Identifiable {
    let id = UUID()
    let day: Date
    let minutes: Double
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack { StatsView() }
        .modelContainer(PreviewData.container)
}
