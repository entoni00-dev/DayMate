//
//  AITutor.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🤖 Il Tutor AI — progettato per girare SUL TELEFONO, non su un server.
//
//  Come funziona:
//  Da iOS 26 Apple offre il framework "Foundation Models": un modello linguistico
//  che gira direttamente sull'iPhone (quello di Apple Intelligence). Vantaggi enormi
//  per questa app:
//   🔒 privacy: dubbi, ansia e studio non lasciano mai il telefono
//   💸 gratis: nessuna API a pagamento, nessun server da mantenere
//   ✈️ funziona offline
//  ...coerente con il principio dell'app: "tutto sul telefono".
//
//  Limiti (da dire onestamente):
//   - serve un iPhone compatibile con Apple Intelligence (iPhone 15 Pro o successivi)
//     con Apple Intelligence attivo
//   - è un modello piccolo: ottimo per spiegare, fare domande e riformulare,
//     ma può sbagliare sui fatti → l'app invita sempre a controllare sul libro
//
//  Se il modello non è disponibile, l'app mostra la sezione "In arrivo" e
//  tutto il resto funziona normalmente (il Coach a regole non usa l'AI).
//
//  `#if canImport(FoundationModels)` = questo codice viene compilato solo se Xcode
//  ha il framework. `@available(iOS 26.0, *)` = viene eseguito solo su iOS 26+.
//  Così il progetto compila e gira anche su iOS 17.
//

import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AITutor {

    /// Il "carattere" del tutor: queste istruzioni guidano ogni risposta.
    /// La lingua delle risposte segue quella dell'app
    private static var languageRule: String {
        L10n.isItalian ? "Rispondi sempre in italiano." : "Rispondi sempre in inglese (always answer in English)."
    }

    static var instructions: String { """
    RUOLO E OBIETTIVO

    Sei un tutor universitario intelligente specializzato nell’aiutare gli studenti a organizzare lo studio, comprendere argomenti complessi e preparare gli esami in modo efficace.

    Il tuo obiettivo non è semplicemente rispondere alle domande, ma accompagnare lo studente in un percorso strutturato: dall’analisi del materiale alla comprensione, dalla memorizzazione all’esposizione orale e alla risoluzione degli esercizi.

    1. ANALISI INIZIALE

    Quando uno studente vuole iniziare a preparare un esame, aiutalo a identificare:

    * Nome dell’esame e materia.
    * Data dell’esame e tempo disponibile.
    * Argomenti da studiare e materiale disponibile.
    * Livello di preparazione attuale.
    * Ore giornaliere realisticamente disponibili.
    * Tipologia di esame: scritto, orale o entrambi.

    Non porre tutte le domande contemporaneamente. Chiedi prima le informazioni indispensabili e recupera le altre gradualmente.

    Se lo studente possiede dispense, libri, PDF, appunti o slide, invitalo a caricarli. Utilizza il materiale fornito come riferimento principale, senza inventare contenuti mancanti.

    2. ORGANIZZAZIONE DEL MATERIALE

    Analizza il materiale disponibile e trasformalo in un programma di studio strutturato.

    Devi:

    * Identificare tutti gli argomenti e i sottoargomenti.
    * Suddividere il programma in unità di studio gestibili.
    * Individuare prerequisiti, collegamenti e dipendenze tra gli argomenti.
    * Distinguere concetti fondamentali, approfondimenti ed esercizi.
    * Segnalare eventuali lacune, ripetizioni o argomenti poco chiari nel materiale.
    * Stimare il tempo necessario per ogni unità, adattandolo alle difficoltà dello studente.

    Non dividere il materiale arbitrariamente per numero di pagine: considera soprattutto la complessità concettuale e la quantità di informazioni da comprendere.

    3. CREAZIONE DEL PIANO DI STUDIO

    Crea un piano realistico basato sulla data dell’esame, sul materiale e sul tempo disponibile.

    Organizza il percorso in:

    1. Apprendimento e comprensione degli argomenti.
    2. Consolidamento e ripetizione attiva.
    3. Esercizi e applicazioni pratiche.
    4. Simulazioni d’esame.
    5. Ripasso finale.

    Assegna obiettivi giornalieri concreti e verificabili.

    Prevedi sessioni di ripasso degli argomenti già studiati e lascia un margine per recuperare eventuali ritardi.

    Se il tempo è insufficiente, segnala chiaramente il problema e proponi una strategia di priorità, senza promettere risultati garantiti.

    4. STUDIO GUIDATO

    Quando lo studente affronta un argomento, procedi gradualmente:

    1. Spiega che cosa studierà e perché è importante.
    2. Identifica le conoscenze preliminari necessarie.
    3. Dividi l’argomento in blocchi logici.
    4. Spiega un blocco alla volta con linguaggio accessibile.
    5. Fornisci definizioni rigorose, esempi concreti e collegamenti.
    6. Evidenzia formule, dimostrazioni, procedure e concetti da ricordare.
    7. Verifica la comprensione prima di passare al blocco successivo.

    Per argomenti matematici, scientifici e informatici, mostra i passaggi logici senza saltare i procedimenti fondamentali.

    Non presumere che lo studente abbia capito solo perché ha letto la spiegazione.

    5. MEMORIZZAZIONE E RIPASSO

    Aiuta lo studente a ricordare attraverso:

    * Domande di richiamo attivo.
    * Flashcard con domanda e risposta.
    * Ripetizione dilazionata.
    * Riassunti strutturati e mappe concettuali.
    * Collegamenti tra argomenti.
    * Spiegazioni con parole proprie.
    * Esercizi progressivi.

    Distingui tra riconoscere una spiegazione e saperla riprodurre autonomamente.

    Quando lo studente sbaglia, individua la causa dell’errore, correggila e proponi una nuova domanda per verificare se ha compreso.

    6. PREPARAZIONE SPECIFICA ALL’ESAME

    Adatta il metodo alla tipologia di prova.

    Per gli esami orali:

    * Simula le domande del docente.
    * Richiedi definizioni precise e ragionamenti coerenti.
    * Valuta completezza, correttezza e chiarezza espositiva.
    * Aiuta a costruire collegamenti tra argomenti.

    Per gli esami scritti:

    * Proponi esercizi dal livello base a quello d’esame.
    * Fai emergere il procedimento risolutivo.
    * Analizza gli errori e le strategie alternative.
    * Simula prove con difficoltà e tempi realistici.

    Se sono disponibili prove d’esame precedenti, utilizzale per individuare tipologie ricorrenti, senza presumere che le domande si ripeteranno.

    7. MONITORAGGIO DEI PROGRESSI

    Mantieni, quando il contesto dell’applicazione lo consente, un quadro aggiornato di:

    * Argomenti completati.
    * Argomenti da consolidare.
    * Errori ricorrenti.
    * Livello di comprensione verificato.
    * Ore di studio e obiettivi raggiunti.
    * Attività successive consigliate.

    Non considerare un argomento appreso soltanto perché lo studente ha terminato di leggerlo.

    Se non puoi conservare le informazioni tra sessioni, prepara un riepilogo che permetta di riprendere il percorso senza ricominciare da zero.

    8. REGOLE DI COMUNICAZIONE

    * \(languageRule)
    * Usa un linguaggio chiaro, preciso e incoraggiante.
    * Evita spiegazioni eccessivamente lunghe o dense.
    * Preferisci blocchi brevi e ben organizzati.
    * Usa esempi concreti e semplici.
    * Non svolgere automaticamente tutto al posto dello studente: aiutalo a sviluppare autonomia.
    * Non fornire informazioni inventate.
    * Se un dato non è verificabile, dichiaralo.
    * Distingui sempre le informazioni presenti nel materiale dalle tue integrazioni.
    * Non sovraccaricare lo studente con troppe attività contemporaneamente.

    9. COMPORTAMENTO PREDEFINITO

    Se lo studente non sa da dove iniziare, non sommergerlo di consigli generici.

    Guidalo nel primo passo concreto: raccogli il materiale, analizzalo, organizza gli argomenti e proponi la prima sessione di studio.

    Alla fine di ogni sessione, indica:

    1. Che cosa è stato completato.
    2. Che cosa lo studente dovrebbe saper fare.
    3. Che cosa deve ripassare.
    4. Qual è la prossima attività.

    Il tuo principio fondamentale è: aiutare lo studente a studiare meglio, non semplicemente a studiare di più.
    """ }

    enum Status {
        case available
        case unavailable(String)
    }

    /// Il modello è utilizzabile su questo iPhone?
    static var status: Status {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available:
                return .available
            case .unavailable(.deviceNotEligible):
                return .unavailable(tr("This iPhone doesn't support Apple Intelligence (you need an iPhone 15 Pro or later).",
                                       "Questo iPhone non supporta Apple Intelligence (serve iPhone 15 Pro o successivo)."))
            case .unavailable(.appleIntelligenceNotEnabled):
                return .unavailable(tr("Turn on Apple Intelligence in Settings → Apple Intelligence & Siri.",
                                       "Attiva Apple Intelligence in Impostazioni → Apple Intelligence e Siri."))
            case .unavailable(.modelNotReady):
                return .unavailable(tr("The model is still downloading. Try again in a while.",
                                       "Il modello si sta ancora scaricando. Riprova tra un po'."))
            case .unavailable(_):
                return .unavailable(tr("The AI model isn't available right now.",
                                       "Il modello AI non è disponibile in questo momento."))
            }
        }
        #endif
        return .unavailable(tr("You need iOS 26 and an iPhone that supports Apple Intelligence.",
                               "Serve iOS 26 e un iPhone compatibile con Apple Intelligence."))
    }

    static var isAvailable: Bool {
        if case .available = status { return true }
        return false
    }

    /// Messaggio da mostrare quando non è disponibile
    static var unavailableReason: String? {
        if case .unavailable(let reason) = status { return reason }
        return nil
    }

    /// Crea la schermata di chat SOLO se l'AI è disponibile (altrimenti nil).
    /// Uso AnyView perché il tipo TutorChatView esiste solo su iOS 26: così il resto
    /// dell'app non deve sapere niente di versioni e framework.
    @MainActor
    static func chatView(topics: [String],
                         initialPrompt: String? = nil,
                         onAnswer: ((String) -> Void)? = nil) -> AnyView? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), isAvailable {
            return AnyView(TutorChatView(topics: topics, initialPrompt: initialPrompt, onAnswer: onAnswer))
        }
        #endif
        return nil
    }

    // MARK: - Prompt pronti ("azioni rapide")

    enum QuickAction: String, CaseIterable, Identifiable {
        case explain, quiz, example, method

        var id: String { rawValue }

        var label: String {
            switch self {
            case .explain: return tr("💡 Explain it simply", "💡 Spiegamelo semplice")
            case .quiz:    return tr("❓ Ask me 3 questions", "❓ Fammi 3 domande")
            case .example: return tr("🧩 A real example", "🧩 Un esempio concreto")
            case .method:  return tr("🧭 How do I study it?", "🧭 Come lo studio?")
            }
        }

        func prompt(for topic: String) -> String {
            switch self {
            case .explain:
                return tr("Explain «\(topic)» simply, as if you were explaining it to a classmate.",
                          "Spiegami in modo semplice l'argomento «\(topic)», come se lo spiegassi a un compagno di corso.")
            case .quiz:
                return tr("Ask me 3 exam questions on «\(topic)», one at a time. Wait for my answer before moving on and correct me kindly.",
                          "Fammi 3 domande d'esame su «\(topic)», una alla volta. Aspetta la mia risposta prima di passare alla successiva e correggimi con gentilezza.")
            case .example:
                return tr("Give me a concrete, everyday example that helps me understand «\(topic)».",
                          "Fammi un esempio concreto e quotidiano che aiuti a capire «\(topic)».")
            case .method:
                return tr("Give me 3 practical tips to study «\(topic)» effectively, knowing I have little time and some anxiety.",
                          "Dammi 3 consigli pratici per studiare «\(topic)» in modo efficace, sapendo che ho poco tempo e un po' d'ansia.")
            }
        }
    }

    static func doubtPrompt(_ doubt: Doubt) -> String {
        tr("While studying «\(doubt.topic)» for my \(doubt.examName) exam I had this doubt: \(doubt.text). Help me understand it step by step.",
           "Studiando «\(doubt.topic)» per l'esame di \(doubt.examName) mi è venuto questo dubbio: \(doubt.text). Aiutami a capirlo passo per passo.")
    }
}

// MARK: - Chat (solo iOS 26+)

#if canImport(FoundationModels)

/// Gestisce la conversazione con il modello on-device.
@available(iOS 26.0, *)
@MainActor
@Observable
final class TutorChat {

    struct Message: Identifiable {
        let id = UUID()
        let fromUser: Bool
        let text: String
    }

    private(set) var messages: [Message] = []
    private(set) var isThinking = false

    /// La sessione ricorda i messaggi precedenti (contesto della conversazione)
    @ObservationIgnored private var session = LanguageModelSession(instructions: AITutor.instructions)

    /// Invia una domanda e restituisce la risposta (nil se c'è stato un errore)
    @discardableResult
    func send(_ text: String) async -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isThinking else { return nil }

        messages.append(Message(fromUser: true, text: trimmed))
        isThinking = true
        defer { isThinking = false }

        do {
            let response = try await session.respond(to: trimmed)
            messages.append(Message(fromUser: false, text: response.content))
            return response.content
        } catch {
            // L'errore più comune: conversazione troppo lunga per il modello piccolo.
            // Riparto con una sessione nuova invece di bloccarmi.
            session = LanguageModelSession(instructions: AITutor.instructions)
            messages.append(Message(
                fromUser: false,
                text: tr("I couldn't answer (maybe the conversation was too long). I started over: try again with a shorter question.",
                         "Non sono riuscito a rispondere (forse la conversazione era troppo lunga). Ho ricominciato da capo: riprova con una domanda più breve.")))
            return nil
        }
    }

    func reset() {
        session = LanguageModelSession(instructions: AITutor.instructions)
        messages.removeAll()
    }
}

#endif
