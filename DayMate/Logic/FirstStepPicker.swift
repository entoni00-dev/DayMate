//
//  FirstStepPicker.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il "cuore" dell'idea: il RISCALDAMENTO iniziale in base a come ti senti.
//
//  Great     → nessun riscaldamento: si parte col primo blocco di studio
//  Sleepy    → nessun riscaldamento: serve energia, non un passo più piccolo
//              (i blocchi corti e il bicchiere d'acqua li gestiscono StudyRhythm e il fumetto)
//  Stressed  → 3 minuti: leggi solo le prime righe del prossimo passo
//  Stuck     → 2 minuti: un gesto fisico minuscolo, tipo "apri il libro"
//
//  Il principio è quello delle "tiny habits" (BJ Fogg, Stanford): abbassare
//  così tanto la soglia d'ingresso che iniziare costa meno che rimandare.
//

import Foundation

enum FirstStepPicker {

    /// Azioni minuscole per quando sei bloccato: nessuna richiede di "studiare" davvero,
    /// servono solo a rompere l'inerzia e a preparare l'ambiente.
    static var tinyActions: [String] {
        [
            tr("Sit at your desk and open the book at the right page",
               "Siediti alla scrivania e apri il libro alla pagina giusta"),
            tr("Put your phone face down, away from you (better: in another room)",
               "Metti il telefono a faccia in giù, lontano da te (meglio in un'altra stanza)"),
            tr("Get a pen, a notebook and a glass of water ready",
               "Prepara penna, quaderno e un bicchiere d'acqua"),
            tr("Read just the chapter title, nothing more",
               "Leggi solo il titolo del capitolo, niente di più"),
            tr("Write today's topic on a sheet of paper",
               "Scrivi su un foglio il nome dell'argomento di oggi"),
            tr("Open your notes and look only at the first page",
               "Apri gli appunti e guarda solo la prima pagina"),
        ]
    }

    /// Il riscaldamento per l'umore scelto (nil = nessun riscaldamento)
    static func warmUp(for mood: Mood, next: StudyStep?) -> PlannedStep? {
        switch mood {
        case .great, .sleepy:
            return nil
        case .stressed:
            if let next {
                return PlannedStep(
                    text: tr("Read just the first lines of «\(next.topic)». Only those, nothing more.",
                             "Leggi solo le prime righe di «\(next.topic)». Solo quelle, niente di più."),
                    minutes: mood.firstTimerMinutes,
                    step: nil)
            }
            return tinyStep(minutes: mood.firstTimerMinutes)
        case .stuck:
            return tinyStep(minutes: mood.firstTimerMinutes)
        }
    }

    /// Un passo minuscolo casuale (usato anche dal pulsante "rendilo più piccolo")
    static func tinyStep(minutes: Int = 2) -> PlannedStep {
        let actions = tinyActions
        return PlannedStep(text: actions.randomElement() ?? actions[0], minutes: minutes, step: nil)
    }
}
