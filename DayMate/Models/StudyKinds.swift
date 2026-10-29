//
//  StudyKinds.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Gli "enum" che descrivono il piano di studio:
//   - ExamKind   → che tipo di esame è (orale, scritto, misto)
//   - Difficulty → quanto è difficile un argomento (cambia i minuti per pagina)
//   - StepKind   → che TIPO di passo è (leggere, richiamare a memoria, esercizio...)
//   - StudyPhase → in che fase del piano siamo (studio, ripasso, simulazione)
//   - TopicDraft → un argomento mentre lo si sta inserendo nel form
//
//  📚 Da dove vengono queste scelte?
//  Ho basato il piano sulla review di Dunlosky et al. (2013), "Improving Students'
//  Learning With Effective Learning Techniques", che ha confrontato 10 tecniche di studio:
//   ✅ utilità ALTA:     verificarsi da soli (practice testing) e studio distribuito nel tempo
//   🟡 utilità MODERATA: chiedersi "perché?", spiegarsi i passaggi, alternare gli argomenti
//   ❌ utilità BASSA:    rileggere, sottolineare, riassumere (da soli)
//  Per questo nel piano ogni lettura è seguita da un passo "a libro chiuso".
//

import SwiftUI

// MARK: - Tipo di esame

enum ExamKind: String, CaseIterable, Identifiable {
    case theory      // orale / teoria
    case exercises   // scritto / esercizi
    case mixed       // entrambi

    var id: String { rawValue }

    var title: String {
        switch self {
        case .theory:    return tr("Theory", "Teoria")
        case .exercises: return tr("Exercises", "Esercizi")
        case .mixed:     return tr("Mixed", "Misto")
        }
    }

    var detail: String {
        switch self {
        case .theory:    return tr("Oral exam or theory questions", "Orale o domande di teoria")
        case .exercises: return tr("Written exam with exercises", "Scritto con esercizi da risolvere")
        case .mixed:     return tr("Theory + exercises", "Teoria + esercizi")
        }
    }

    var hasExercises: Bool { self != .theory }
    var hasTheory: Bool { self != .exercises }
}

// MARK: - Difficoltà di un argomento

enum Difficulty: Int, CaseIterable, Identifiable {
    case easy = 0
    case medium = 1
    case hard = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy:   return tr("Easy", "Facile")
        case .medium: return tr("Medium", "Media")
        case .hard:   return tr("Hard", "Difficile")
        }
    }

    /// Minuti per pagina di STUDIO (non di lettura veloce!).
    /// Sono stime di partenza: l'app poi le corregge misurando quanto ci metti
    /// davvero (vedi `Exam.speedFactor`).
    var minutesPerPage: Int {
        switch self {
        case .easy:   return 3
        case .medium: return 5
        case .hard:   return 7
        }
    }

    /// Quante pagine per ogni passo di lettura: così ogni passo dura ~10-15 minuti.
    var pagesPerStep: Int {
        switch self {
        case .easy:   return 4   // 4 × 3 = 12 min
        case .medium: return 3   // 3 × 5 = 15 min
        case .hard:   return 2   // 2 × 7 = 14 min
        }
    }

    /// Minuti per un esercizio
    var minutesPerExercise: Int {
        switch self {
        case .easy:   return 8
        case .medium: return 12
        case .hard:   return 18
        }
    }
}

// MARK: - Fase del piano

enum StudyPhase: Int, CaseIterable, Identifiable {
    case learn = 0
    case review = 1
    case simulate = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .learn:    return tr("Study", "Studio")
        case .review:   return tr("Review", "Ripasso")
        case .simulate: return tr("Mock exam", "Simulazione")
        }
    }

    var emoji: String {
        switch self {
        case .learn:    return "📖"
        case .review:   return "🔁"
        case .simulate: return "🎯"
        }
    }

    var detail: String {
        switch self {
        case .learn:
            return tr("Understand the topics, one small piece at a time.",
                      "Capire gli argomenti, un pezzetto alla volta.")
        case .review:
            return tr("Recall what you studied from memory, days later.",
                      "Richiamare a memoria quello che hai studiato, a distanza di giorni.")
        case .simulate:
            return tr("Practise in real exam conditions.",
                      "Allenarsi nelle condizioni dell'esame.")
        }
    }
}

// MARK: - Tipo di passo

enum StepKind: String, CaseIterable {
    case overview     // sguardo d'insieme
    case read         // lettura di poche pagine
    case recall       // a libro chiuso: cosa ricordo?
    case flashback    // ripasso lampo dell'argomento precedente
    case map          // schema da memoria
    case exercise     // esercizio
    case review       // ripasso attivo (fase 2)
    case simulation   // simulazione d'esame (fase 3)

    var emoji: String {
        switch self {
        case .overview:   return "🗺️"
        case .read:       return "📖"
        case .recall:     return "🧠"
        case .flashback:  return "⚡️"
        case .map:        return "🕸️"
        case .exercise:   return "✏️"
        case .review:     return "🔁"
        case .simulation: return "🎯"
        }
    }

    var label: String {
        switch self {
        case .overview:   return tr("Overview", "Sguardo d'insieme")
        case .read:       return tr("Reading", "Lettura")
        case .recall:     return tr("Book closed", "A libro chiuso")
        case .flashback:  return tr("Quick recall", "Ripasso lampo")
        case .map:        return tr("Mind map", "Schema")
        case .exercise:   return tr("Exercise", "Esercizio")
        case .review:     return tr("Active review", "Ripasso attivo")
        case .simulation: return tr("Mock exam", "Simulazione")
        }
    }

    var phase: StudyPhase {
        switch self {
        case .review:     return .review
        case .simulation: return .simulate
        default:          return .learn
        }
    }

    /// Il consiglio mostrato durante il passo. Solo cose supportate dalla ricerca
    /// sull'apprendimento, senza esagerare le promesse.
    var tip: String {
        switch self {
        case .overview:
            return tr("Look at headings, figures and bold words without reading everything. Getting the structure first helps you see where the details fit.",
                      "Guarda titoli, grafici e parole in grassetto senza leggere tutto. Farsi prima un'idea della struttura aiuta a capire dove si incastrano i dettagli.")
        case .read:
            return tr("Read to understand, not to reach the end. If a sentence isn't clear, ask yourself \"why is it so?\" and note the question in the margin. Don't highlight everything: it feels like learning, but helps little.",
                      "Leggi per capire, non per arrivare in fondo. Se una frase non è chiara, chiediti \"perché è così?\" e segna la domanda a margine. Evita di sottolineare tutto: dà l'illusione di sapere, ma serve poco.")
        case .recall:
            return tr("Close the book and write (or say out loud) what you remember. Then reopen it and check what was missing. It's hard work, and that effort is exactly what makes memories stick: testing yourself is one of the most effective techniques there is.",
                      "Chiudi il libro e scrivi (o di' a voce) quello che ricordi. Poi riapri e controlla cosa mancava. È faticoso, ed è proprio quella fatica che fissa i ricordi: verificarsi è una delle tecniche più efficaci in assoluto.")
        case .flashback:
            return tr("Two minutes to recall the previous topic without looking. Remembering after some time strengthens memory far more than re-reading.",
                      "Due minuti per ricordare l'argomento precedente senza guardare. Richiamare a distanza di tempo rafforza la memoria molto più che rileggere.")
        case .map:
            return tr("Draw the main concepts and link them with arrows, first from memory, then complete it with the book. Where you can't connect things, you've found what to review.",
                      "Disegna i concetti principali e collegali con frecce, prima a memoria, poi completa col libro. Dove non sai collegare, hai trovato cosa ripassare.")
        case .exercise:
            return tr("Try on your own for at least 5 minutes before looking at the solution. Even if you get it wrong, the attempt makes the solution easier to remember.",
                      "Prova da solo per almeno 5 minuti prima di guardare la soluzione. Anche se sbagli, il tentativo rende la soluzione più facile da ricordare.")
        case .review:
            return tr("Don't re-read: ask yourself the questions your professor would ask and answer out loud. Mark what you can't answer and check only that.",
                      "Non rileggere: fatti le domande che ti farebbe il prof e rispondi a voce. Segna ciò che non ti viene e ricontrolla solo quello.")
        case .simulation:
            return tr("Practise like the real exam: time limit, no notes, phone in another room. Then correct it and list your mistakes: that's your review list.",
                      "Allenati come all'esame: tempo limitato, niente appunti, telefono in un'altra stanza. Poi correggi e annota gli errori: sono la tua lista di ripasso.")
        }
    }
}

// MARK: - Argomento in fase di inserimento

/// Un argomento come lo inserisce l'utente nel form (prima di diventare passi).
struct TopicDraft: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var pages: Int
    var difficulty: Difficulty
}
