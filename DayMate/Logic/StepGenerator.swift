//
//  StepGenerator.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Trasforma "argomenti + pagine + difficoltà" in un piano di passi realistico.
//
//  🔄 Versione 2 — cosa non andava nella v1:
//  Ogni argomento diventava sempre 6 passi uguali ("leggi la prima pagina", "riassumi"...),
//  sia che fosse di 3 pagine sia di 60. I salti tra un passo e l'altro erano enormi
//  e i tempi non c'entravano niente con la realtà.
//
//  ✅ Ora il piano ha 3 FASI:
//
//   1. STUDIO (per ogni argomento)
//      ⚡️ ripasso lampo dell'argomento precedente (dal 2° argomento in poi)
//      🗺️ sguardo d'insieme
//      📖 lettura di 2-4 pagine  ─┐  ripetuto finché
//      🧠 a libro chiuso          ─┘  non finiscono le pagine
//      🕸️ schema da memoria
//      ✏️ esercizi (se l'esame li prevede)
//
//   2. RIPASSO — un ripasso attivo per argomento, a distanza di giorni dallo studio
//   3. SIMULAZIONE — prova nelle condizioni dell'esame
//
//  I minuti sono STIME (pagine × minuti per pagina). Poi l'app misura quanto ci metti
//  davvero e corregge tutte le stime successive (vedi Exam.speedFactor).
//

import Foundation

enum StepGenerator {

    /// Crea tutti i passi di un esame (oggetti SwiftData pronti da salvare).
    static func makePlan(topics: [TopicDraft], kind: ExamKind) -> [StudyStep] {
        makeDrafts(topics: topics, kind: kind).toSteps(startingAt: 0)
    }

    /// Stessa cosa ma con semplici struct: non tocca il database, quindi posso
    /// usarla anche per l'anteprima live nel form senza creare oggetti inutili.
    static func makeDrafts(topics: [TopicDraft], kind: ExamKind) -> [StepDraft] {
        var builder = PlanBuilder()

        // FASE 1 — Studio, argomento per argomento
        for (index, topic) in topics.enumerated() {
            let previous = index > 0 ? topics[index - 1].name : nil
            addLearningSteps(for: topic, previousTopic: previous, kind: kind, to: &builder)
        }

        // FASE 2 — Ripasso attivo (dopo aver visto tutti gli argomenti = studio distanziato)
        for topic in topics {
            addReviewSteps(for: topic, kind: kind, to: &builder)
        }

        // FASE 3 — Simulazione d'esame
        addSimulationSteps(kind: kind, to: &builder)

        return builder.steps
    }

    /// Solo la fase di studio di un argomento aggiunto DOPO (dalla schermata dell'esame).
    /// Lo aggiungo in coda partendo da `startingAt`.
    static func makeLearningSteps(for topic: TopicDraft, kind: ExamKind, startingAt start: Int) -> [StudyStep] {
        var builder = PlanBuilder()
        addLearningSteps(for: topic, previousTopic: nil, kind: kind, to: &builder)
        addReviewSteps(for: topic, kind: kind, to: &builder)
        return builder.steps.toSteps(startingAt: start)
    }

    // MARK: - Fase 1: Studio

    private static func addLearningSteps(for topic: TopicDraft,
                                         previousTopic: String?,
                                         kind: ExamKind,
                                         to builder: inout PlanBuilder) {
        let name = topic.name
        let difficulty = topic.difficulty
        let pages = max(1, topic.pages)

        // ⚡️ Ripasso lampo dell'argomento precedente: richiamo distanziato a costo quasi zero
        if let previousTopic {
            builder.add(tr("Without looking, write down in 3 minutes what you remember about «\(previousTopic)»",
                           "Senza guardare, scrivi in 3 minuti cosa ricordi di «\(previousTopic)»"),
                        topic: name, minutes: 3, kind: .flashback)
        }

        // 🗺️ Sguardo d'insieme: circa 1 minuto ogni 5 pagine, tra 3 e 10 minuti
        builder.add(tr("Skim «\(name)»: look only at headings, figures and bold words (\(pages) pp.)",
                       "Sfoglia «\(name)»: guarda solo titoli, figure e parole in grassetto (\(pages) pag.)"),
                    topic: name, minutes: clamp(pages / 5, min: 3, max: 10), kind: .overview)

        // 📖 + 🧠 Lettura a blocchi di poche pagine, ognuno seguito dal richiamo a memoria.
        // (Anche negli esami "solo esercizi" la teoria va capita prima di fare gli esercizi.)
        do {
            var start = 1
            while start <= pages {
                let end = min(start + difficulty.pagesPerStep - 1, pages)
                let chunkPages = end - start + 1
                let readMinutes = chunkPages * difficulty.minutesPerPage
                let range = start == end
                    ? tr("p. \(start)", "pag. \(start)")
                    : tr("pp. \(start)–\(end)", "pagg. \(start)–\(end)")

                builder.add(tr("Read \(range) of «\(name)»", "Leggi \(range) di «\(name)»"),
                            topic: name, minutes: readMinutes, kind: .read)

                // Il richiamo vale circa 1/3 del tempo di lettura (minimo 3 minuti)
                builder.add(tr("Book closed: write what you remember of \(range), then check what's missing",
                               "A libro chiuso: scrivi cosa ricordi di \(range), poi controlla cosa manca"),
                            topic: name, minutes: max(3, Int((Double(readMinutes) * 0.3).rounded())), kind: .recall)

                start = end + 1
            }
        }

        // 🕸️ Schema finale dell'argomento: mezzo minuto per pagina, tra 8 e 20 minuti
        builder.add(tr("Draw a mind map of «\(name)» from memory, then complete it with the book",
                       "Fai uno schema di «\(name)» a memoria, poi completalo col libro"),
                    topic: name, minutes: clamp(pages / 2, min: 8, max: 20), kind: .map)

        // ✏️ Esercizi
        if kind.hasExercises {
            let count = kind == .exercises
                ? clamp(pages / 6, min: 3, max: 8)
                : clamp(pages / 10, min: 2, max: 5)
            for number in 1...count {
                builder.add(tr("Exercise \(number) of \(count) on «\(name)»: try on your own before looking at the solution",
                               "Esercizio \(number) di \(count) su «\(name)»: prova da solo prima di guardare la soluzione"),
                            topic: name, minutes: difficulty.minutesPerExercise, kind: .exercise)
            }
        }
    }

    // MARK: - Fase 2: Ripasso

    private static func addReviewSteps(for topic: TopicDraft, kind: ExamKind, to builder: inout PlanBuilder) {
        let name = topic.name
        let readMinutes = max(1, topic.pages) * topic.difficulty.minutesPerPage

        // Circa il 20% del tempo di lettura, tra 10 e 30 minuti
        let reviewMinutes = clamp(Int(Double(readMinutes) * 0.2), min: 10, max: 30)

        if kind.hasTheory {
            builder.add(tr("Active review of «\(name)»: ask yourself exam questions and answer out loud, no notes",
                           "Ripasso attivo di «\(name)»: fatti le domande d'esame e rispondi a voce, senza appunti"),
                        topic: name, minutes: reviewMinutes, kind: .review)
        }
        if kind.hasExercises {
            builder.add(tr("Redo 2 exercises on «\(name)» without looking at your notes",
                           "Rifai 2 esercizi di «\(name)» senza guardare gli appunti"),
                        topic: name, minutes: topic.difficulty.minutesPerExercise * 2, kind: .review)
        }
    }

    // MARK: - Fase 3: Simulazione

    private static func addSimulationSteps(kind: ExamKind, to builder: inout PlanBuilder) {
        let topic = tr("Mock exam", "Simulazione d'esame")

        if kind.hasExercises {
            builder.add(tr("Written mock, part 1: half of a past exam paper, timed",
                           "Simulazione scritta, parte 1: metà di una prova d'esame passata, cronometrata"),
                        topic: topic, minutes: 30, kind: .simulation)
            builder.add(tr("Written mock, part 2: the other half, still timed",
                           "Simulazione scritta, parte 2: l'altra metà, sempre cronometrata"),
                        topic: topic, minutes: 30, kind: .simulation)
            builder.add(tr("Correct the mock exam and list the mistakes to review",
                           "Correggi la simulazione e scrivi la lista degli errori da ripassare"),
                        topic: topic, minutes: 15, kind: .simulation)
        }
        if kind.hasTheory {
            builder.add(tr("Oral mock: pick 3 random topics and explain them out loud like at the exam",
                           "Simulazione orale: scegli 3 argomenti a caso e spiegali ad alta voce come all'esame"),
                        topic: topic, minutes: 20, kind: .simulation)
            builder.add(tr("Review only the points where you got stuck during the mock",
                           "Ripassa solo i punti in cui ti sei bloccato durante la simulazione"),
                        topic: topic, minutes: 15, kind: .simulation)
        }
    }

    // MARK: - Utility

    /// Divide un testo incollato in più argomenti.
    /// Es. "Limiti, Derivate; Integrali" → ["Limiti", "Derivate", "Integrali"]
    static func splitTopics(_ text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet(charactersIn: ",;\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// Tiene un valore dentro un intervallo
    static func clamp(_ value: Int, min lower: Int, max upper: Int) -> Int {
        Swift.min(Swift.max(value, lower), upper)
    }

    /// Stima in minuti di tutto il piano, senza creare oggetti nel database
    /// (la uso nell'anteprima del form "Nuovo esame").
    static func estimate(topics: [TopicDraft], kind: ExamKind) -> (steps: Int, minutes: Int) {
        let drafts = makeDrafts(topics: topics, kind: kind)
        return (drafts.count, drafts.reduce(0) { $0 + $1.minutes })
    }
}

// MARK: - Bozze di passi

/// Un passo "in bozza": una semplice struct, non ancora salvata nel database.
struct StepDraft {
    let title: String
    let topic: String
    let minutes: Int
    let kind: StepKind
}

extension Array where Element == StepDraft {
    /// Converte le bozze in StudyStep numerati a partire da `start`
    func toSteps(startingAt start: Int) -> [StudyStep] {
        enumerated().map { index, draft in
            StudyStep(title: draft.title, topic: draft.topic, minutes: draft.minutes,
                      order: start + index, kind: draft.kind)
        }
    }
}

/// Piccolo aiutante per accumulare i passi mentre li creo.
private struct PlanBuilder {
    var steps: [StepDraft] = []

    mutating func add(_ title: String, topic: String, minutes: Int, kind: StepKind) {
        steps.append(StepDraft(title: title, topic: topic, minutes: minutes, kind: kind))
    }
}
