//
//  CoachEngine.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il "coach" che funziona GIÀ OGGI, su qualsiasi iPhone, senza AI.
//
//  È un motore a regole: guarda i tuoi dati (sessioni, tempi reali, umore, piano)
//  e ne tira fuori consigli personalizzati. Niente magia, niente server.
//
//  Perché partire da qui e non subito da un'AI?
//   1. Funziona su tutti i telefoni, anche quelli senza Apple Intelligence.
//   2. È prevedibile: so esattamente cosa dirà e perché (un'AI può inventare).
//   3. Quando arriverà il Tutor AI, questi stessi dati saranno il suo "contesto".
//

import SwiftUI

struct CoachTip: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let text: String
    let color: Color
}

enum CoachEngine {

    static func tips(exams: [Exam], sessions: [StudySession], now: Date = .now) -> [CoachTip] {
        var tips: [CoachTip] = []
        let calendar = Calendar.current
        let upcoming = exams.filter { !$0.isPast }

        // 0 — Nessun dato: consiglio di partenza
        if sessions.isEmpty {
            tips.append(CoachTip(
                emoji: "🌱",
                title: tr("The first step is the smallest", "Il primo passo è il più piccolo"),
                text: tr("You don't have to decide to \"study all afternoon\". Just decide to open the book for 2 minutes. The rest comes later.",
                         "Non devi decidere di \"studiare tutto il pomeriggio\". Decidi solo di aprire il libro per 2 minuti. Il resto viene dopo."),
                color: Theme.leaf))
        }

        // 1 — Il piano ci sta nel tempo che hai?
        for exam in upcoming {
            let plan = StudyPlanner.plan(for: exam, now: now)
            if !plan.fits && plan.neededPerDay > 0 {
                tips.append(CoachTip(
                    emoji: "⚠️",
                    title: tr("\(exam.name): the plan is tight", "\(exam.name): il piano è stretto"),
                    text: tr("You'd need about \(plan.neededPerDay.asDuration) a day, but you set \(exam.dailyMinutes.asDuration). Better to know now: you can add daily time, drop less important pages or consider the next exam date.",
                             "Servirebbero circa \(plan.neededPerDay.asDuration) al giorno, ma ne hai indicati \(exam.dailyMinutes.asDuration). Meglio saperlo ora: puoi aumentare il tempo giornaliero, togliere qualche pagina meno importante o valutare l'appello successivo."),
                    color: Theme.rust))
            }
        }

        // 2 — Calibrazione: quanto sei veloce rispetto alle stime
        for exam in upcoming where exam.measuredSteps.count >= 3 {
            let factor = exam.speedFactor
            let percent = Int((abs(factor - 1) * 100).rounded())
            if factor < 0.85 {
                tips.append(CoachTip(
                    emoji: "⚡️",
                    title: tr("You're faster than expected", "Sei più veloce del previsto"),
                    text: tr("On \(exam.name) you take about \(percent)% less than estimated. I shortened the plan's times: now they're YOUR times.",
                             "Su \(exam.name) ci metti circa il \(percent)% in meno delle stime. Ho accorciato i tempi del piano: ora sono i TUOI tempi."),
                    color: Theme.water))
            } else if factor > 1.15 {
                tips.append(CoachTip(
                    emoji: "🐢",
                    title: tr("You need a bit more time, and that's normal", "Ti serve un po' più tempo, ed è normale"),
                    text: tr("On \(exam.name) you take about \(percent)% more than estimated. It happens with new or dense topics. I made the plan longer so it's realistic.",
                             "Su \(exam.name) ci metti circa il \(percent)% in più delle stime. Succede con argomenti nuovi o densi. Ho allungato il piano, così è realistico."),
                    color: Theme.honey))
            }
        }

        // 3 — Umore prima/dopo
        let rated = sessions.compactMap { $0.improved }
        if rated.count >= 3 {
            let improved = rated.filter { $0 }.count
            let percent = Int((Double(improved) / Double(rated.count) * 100).rounded())
            if percent >= 50 {
                tips.append(CoachTip(
                    emoji: "💚",
                    title: tr("Starting makes you feel better", "Iniziare ti fa stare meglio"),
                    text: tr("In \(percent)% of sessions you felt calmer at the end than when you started. Next time you feel stuck, remember this number.",
                             "Nel \(percent)% delle sessioni alla fine eri più tranquillo di quando hai iniziato. La prossima volta che ti senti bloccato, ricordati di questo numero."),
                    color: Theme.leaf))
            }
        }

        // 4 — Pause: le fai davvero?
        let totalBlocks = sessions.reduce(0) { $0 + $1.blocks }
        let totalBreaks = sessions.reduce(0) { $0 + $1.realBreaks }
        if totalBlocks >= 4 && Double(totalBreaks) < Double(totalBlocks) * 0.4 {
            tips.append(CoachTip(
                emoji: "🚶",
                title: tr("You're forgetting your breaks", "Ti stai dimenticando le pause"),
                text: tr("You did \(totalBlocks) blocks but only \(totalBreaks) real breaks. Short breaks away from the screen help you stay focused: they're not wasted time.",
                         "Hai fatto \(totalBlocks) blocchi ma solo \(totalBreaks) pause vere. Le pause brevi lontano dallo schermo aiutano a mantenere la concentrazione: non sono tempo perso."),
                color: Theme.honey))
        }

        // 5 — L'orario in cui inizi più spesso → intenzione "se-allora"
        if sessions.count >= 3 {
            let byHour = Dictionary(grouping: sessions) { calendar.component(.hour, from: $0.startedAt) }
            if let best = byHour.max(by: { $0.value.count < $1.value.count }), best.value.count >= 2 {
                tips.append(CoachTip(
                    emoji: "⏰",
                    title: tr("Your time: around \(best.key):00", "Il tuo orario: verso le \(best.key)"),
                    text: tr("You often start around \(best.key):00. Turn it into a precise plan: \"At \(best.key):00, after coffee, I open the book\". \"When X happens, I do Y\" plans make it more likely you'll really start.",
                             "Inizi spesso verso le \(best.key). Trasformalo in un piano preciso: \"Alle \(best.key), dopo il caffè, apro il libro\". Le intenzioni del tipo \"quando succede X, faccio Y\" aumentano la probabilità di iniziare davvero."),
                    color: Theme.lilac))
            }
        }

        // 6 — Da qualche giorno non studi e l'esame si avvicina
        if let last = sessions.map({ $0.startedAt }).max(),
           let soonest = upcoming.min(by: { $0.date < $1.date }),
           soonest.daysLeft <= 14 {
            let idleDays = calendar.dateComponents([.day], from: calendar.startOfDay(for: last),
                                                   to: calendar.startOfDay(for: now)).day ?? 0
            if idleDays >= 2 {
                tips.append(CoachTip(
                    emoji: "🫶",
                    title: tr("No guilt, just one step", "Nessuna colpa, solo un passo"),
                    text: tr("It's been \(idleDays) days since you opened \(soonest.name). It happens. You don't need to catch up on everything today: the plan has already rebalanced. Today 2 minutes are enough.",
                             "Sono \(idleDays) giorni che non apri \(soonest.name). Succede. Non serve recuperare tutto oggi: il piano si è già ridistribuito. Oggi bastano 2 minuti."),
                    color: Theme.blush))
            }
        }

        // 7 — Un consiglio "scientifico" del giorno (ruota ogni giorno)
        tips.append(dailyScienceTip(now: now))

        return tips
    }

    /// Un consiglio basato sulla ricerca, diverso ogni giorno
    static func dailyScienceTip(now: Date = .now) -> CoachTip {
        let pool: [CoachTip] = [
            CoachTip(emoji: "🧠",
                     title: tr("Test yourself, don't re-read", "Verificati, non rileggere"),
                     text: tr("Closing the book and trying to remember is one of the most effective study techniques there is. Re-reading feels like knowing, but sticks much less.",
                              "Chiudere il libro e provare a ricordare è una delle tecniche di studio più efficaci in assoluto. Rileggere dà la sensazione di sapere, ma fissa molto meno."),
                     color: Theme.water),
            CoachTip(emoji: "📅",
                     title: tr("A little every day", "Meglio poco ogni giorno"),
                     text: tr("Spreading study over several days works much better than cramming it all before the exam. That's why the plan puts review days after study.",
                              "Distribuire lo studio su più giorni funziona molto meglio che concentrarlo tutto prima dell'esame. Per questo il piano mette il ripasso a distanza dallo studio."),
                     color: Theme.leaf),
            CoachTip(emoji: "😴",
                     title: tr("Sleep is part of studying", "Il sonno fa parte dello studio"),
                     text: tr("While you sleep, your brain consolidates what you learned. Staying up late the night before the exam often does more harm than good.",
                              "Durante il sonno il cervello consolida quello che hai imparato. Tirare tardi la notte prima dell'esame spesso fa più male che bene."),
                     color: Theme.lilac),
            CoachTip(emoji: "❓",
                     title: tr("Ask yourself \"why?\"", "Chiediti \"perché?\""),
                     text: tr("While studying, ask yourself why something is true and how it connects to what you already know. Explaining the steps helps you understand, not just memorise.",
                              "Mentre studi, chiediti perché una cosa è vera e come si collega a quello che già sai. Spiegarsi i passaggi aiuta a capire, non solo a memorizzare."),
                     color: Theme.honey),
            CoachTip(emoji: "🔀",
                     title: tr("Mix your exercises", "Mescola gli esercizi"),
                     text: tr("Alternating different kinds of exercises (instead of 10 identical ones in a row) is harder, but trains you to recognise WHICH method to use, like at the exam.",
                              "Negli esercizi, alternare tipi diversi (invece di farne 10 uguali di fila) è più faticoso ma ti allena a riconoscere QUALE metodo usare, come all'esame."),
                     color: Theme.rust),
            CoachTip(emoji: "📵",
                     title: tr("Phone in another room", "Telefono in un'altra stanza"),
                     text: tr("Every notification breaks your focus, and getting it back takes time. The easiest way not to check your phone is not to have it within reach.",
                              "Ogni notifica interrompe la concentrazione e riprenderla richiede tempo. Il modo più semplice per non guardarlo è non averlo a portata di mano."),
                     color: Theme.blush),
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 0
        return pool[day % pool.count]
    }
}
