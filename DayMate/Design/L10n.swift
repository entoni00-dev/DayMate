//
//  L10n.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🌍 Italiano + inglese, scelti DALL'UTENTE.
//
//  L'app parte in italiano. Si cambia lingua:
//   - nella prima schermata (il selettore IT / EN in alto)
//   - in Impostazioni → Lingua
//  La scelta viene salvata in UserDefaults (sul telefono) e resta anche riaprendo l'app.
//
//  Ogni testo è scritto così:   tr("Start", "Inizia")   → inglese, italiano
//
//  Perché non uno String Catalog (.xcstrings)?
//  Lo String Catalog segue la lingua del TELEFONO, mentre qui la lingua la sceglie
//  l'utente dentro l'app. Con tr() inoltre:
//   1. inglese e italiano stanno sulla stessa riga → impossibile dimenticare una traduzione
//   2. funziona anche per i testi creati dalla logica (passi, consigli, notifiche)
//   3. niente chiavi con %@ / %lld da tenere allineate a mano
//

import Foundation

/// Le lingue dell'app
enum AppLanguage: String, CaseIterable, Identifiable {
    case italian = "it"
    case english = "en"

    var id: String { rawValue }

    /// Il nome della lingua scritto nella lingua stessa (come fa iOS)
    var name: String {
        switch self {
        case .italian: return "Italiano"
        case .english: return "English"
        }
    }

    var shortName: String { rawValue.uppercased() }

    var flag: String {
        switch self {
        case .italian: return "🇮🇹"
        case .english: return "🇬🇧"
        }
    }

    var locale: Locale {
        switch self {
        case .italian: return Locale(identifier: "it_IT")
        case .english: return Locale(identifier: "en_GB")   // "Tuesday, 20 October 2026", come in Sketch
        }
    }
}

enum L10n {
    /// Chiave in UserDefaults (usata anche con @AppStorage)
    static let languageKey = "appLanguage"

    /// La lingua scelta. Se l'utente non ha mai scelto: italiano.
    static var language: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: languageKey) ?? "") ?? .italian
    }

    static var isItalian: Bool { language == .italian }

    /// Locale per date e numeri, coerente con la lingua dei testi
    static var locale: Locale { language.locale }
}

/// Restituisce il testo nella lingua scelta.
func tr(_ english: String, _ italian: String) -> String {
    L10n.isItalian ? italian : english
}

// MARK: - Date già formattate

extension Date {
    /// "martedì 20 ottobre 2026" / "Tuesday, 20 October 2026"
    var longDayText: String {
        let text = formatted(.dateTime.weekday(.wide).day().month(.wide).year().locale(L10n.locale))
        // In italiano i giorni sono minuscoli: in un titolo è più bello con la maiuscola
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    /// "gio 29 ottobre" / "Thu, 29 October"
    var shortDayText: String {
        let text = formatted(.dateTime.weekday(.abbreviated).day().month(.wide).locale(L10n.locale))
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}
