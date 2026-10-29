//
//  StudyScienceView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "What really works": le tecniche di studio valutate dalla ricerca.
//
//  Fonte principale: Dunlosky, Rawson, Marsh, Nathan & Willingham (2013),
//  "Improving Students' Learning With Effective Learning Techniques",
//  Psychological Science in the Public Interest. Hanno valutato 10 tecniche
//  su molti studi e assegnato un'utilità alta, moderata o bassa.
//

import SwiftUI

struct StudyScienceView: View {

    enum Rating {
        case high, moderate, low

        var title: String {
            switch self {
            case .high:     return tr("Very effective", "Molto efficace")
            case .moderate: return tr("Useful", "Utile")
            case .low:      return tr("Not very effective", "Poco efficace")
            }
        }

        var color: Color {
            switch self {
            case .high:     return Theme.leaf
            case .moderate: return Theme.honey
            case .low:      return Theme.rust
            }
        }
    }

    struct Technique: Identifiable {
        let id = UUID()
        let emoji: String
        let name: String
        let rating: Rating
        let what: String
        let inTheApp: String
    }

    private let techniques: [Technique] = [
        Technique(emoji: "🧠", name: tr("Testing yourself", "Verificarsi da soli"), rating: .high,
                  what: tr("Trying to remember without looking: questions, flashcards, exercises, saying it out loud.",
                           "Provare a ricordare senza guardare: domande, flashcard, esercizi, ripetere a voce."),
                  inTheApp: tr("Every reading step is followed by a \"book closed\" step.",
                               "Ogni lettura è seguita da un passo \"a libro chiuso\".")),
        Technique(emoji: "📅", name: tr("Spaced study", "Studio distribuito"), rating: .high,
                  what: tr("Studying a little every day and reviewing days later, instead of cramming at the end.",
                           "Studiare un po' ogni giorno e ripassare a distanza di giorni, invece di concentrare tutto alla fine."),
                  inTheApp: tr("The plan spreads the work over the days and puts review after study.",
                               "Il piano divide il lavoro sui giorni e mette il ripasso dopo lo studio.")),
        Technique(emoji: "❓", name: tr("Asking \"why?\"", "Chiedersi \"perché?\""), rating: .moderate,
                  what: tr("Asking yourself why a fact is true and how it connects to what you already know.",
                           "Domandarsi perché un fatto è vero e come si collega a ciò che sai già."),
                  inTheApp: tr("It's the tip for reading steps.", "È il consiglio dei passi di lettura.")),
        Technique(emoji: "🗣️", name: tr("Explaining the steps", "Spiegarsi i passaggi"), rating: .moderate,
                  what: tr("Explaining every step to yourself (or a classmate) while studying or solving a problem.",
                           "Spiegare a se stessi (o a un compagno) ogni passaggio mentre studi o risolvi un problema."),
                  inTheApp: tr("Oral mock exam and active review out loud.", "Simulazione orale e ripasso attivo a voce.")),
        Technique(emoji: "🔀", name: tr("Mixing topics", "Alternare gli argomenti"), rating: .moderate,
                  what: tr("Mixing different kinds of exercises instead of doing many identical ones in a row.",
                           "Mescolare tipi di esercizi diversi invece di farne tanti uguali di fila."),
                  inTheApp: tr("The \"quick recall\" of the previous topic at the start of each one.",
                               "Il \"ripasso lampo\" dell'argomento precedente all'inizio di ognuno.")),
        Technique(emoji: "📝", name: tr("Summarising", "Riassumere"), rating: .low,
                  what: tr("Useful only if you already summarise well; on its own it gives little for the time it takes.",
                           "Utile solo se sai già riassumere bene; da solo, rende poco rispetto al tempo che richiede."),
                  inTheApp: tr("The mind map is done from memory: it's a recall exercise, not copying.",
                               "Lo schema si fa a memoria: è un esercizio di richiamo, non di copiatura.")),
        Technique(emoji: "🖍️", name: tr("Highlighting", "Sottolineare"), rating: .low,
                  what: tr("It feels like work, but on its own it helps little with remembering.",
                           "Dà l'impressione di lavorare, ma da solo aiuta poco a ricordare."),
                  inTheApp: tr("No step asks you to highlight.", "Nessun passo chiede di sottolineare.")),
        Technique(emoji: "🔁", name: tr("Re-reading", "Rileggere"), rating: .low,
                  what: tr("The second reading feels easier and creates the illusion of knowing. Better to close the book and test yourself.",
                           "La seconda lettura sembra più facile e crea l'illusione di sapere. Meglio chiudere il libro e verificarsi."),
                  inTheApp: tr("Review is active: questions and answers, not re-reading.",
                               "Il ripasso è attivo: domande e risposte, non rilettura.")),
    ]

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                BackPill(title: "Coach")
                ScreenHeader(eyebrow: tr("Research says", "Dice la ricerca"),
                             title: tr("What really works", "Cosa funziona davvero"),
                             subtitle: tr("Not all study techniques are equal. A large review of hundreds of studies (Dunlosky and colleagues, 2013) compared them: here's what came out and how DayMate uses it.",
                                          "Non tutte le tecniche di studio sono uguali. Una grande revisione di centinaia di studi (Dunlosky e colleghi, 2013) le ha confrontate: ecco cosa è emerso e come DayMate lo usa."))

                ForEach(techniques) { technique in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(technique.emoji).font(.title2)
                            Text(technique.name)
                                .font(.dmHeadline)
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            Text(technique.rating.title)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(technique.rating.color, in: Capsule())
                        }
                        Text(technique.what)
                            .font(.subheadline)
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Label(technique.inTheApp, systemImage: "app.badge.checkmark")
                            .font(.caption)
                            .foregroundStyle(Theme.mute)
                    }
                    .dmCard()
                }

                Text(tr("Note: \"not very effective\" doesn't mean useless, but that it gives little for the time it takes, especially if it's the only thing you do.",
                        "Nota: \"poco efficace\" non vuol dire inutile, ma che rende poco rispetto al tempo che richiede, soprattutto se è l'unica cosa che fai."))
                    .font(.footnote)
                    .foregroundStyle(Theme.mute)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .dmScreen()
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack { StudyScienceView() }
}
