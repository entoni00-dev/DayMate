//
//  Theme.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🎨 La palette "Ube night" (dal file Sketch, pagina "Colors").
//  L'ube è un tubero viola delle Filippine: da lì il nome e il colore principale.
//
//   background  #1A1530  → lo sfondo di tutte le schermate (blu-viola molto scuro)
//   card        #262044  → le card e le liste
//   highlight   #332A5C  → card in evidenza, icone, campi
//   main        #9F7BFF  → il viola dei bottoni principali
//   lightMain   #CDB9FF  → link e icone ("‹ Today", "Cancel")
//   accent      #7EF0C8  → il verde menta: progressi, spunte, "NEXT TINY STEP"
//   text        #F1EDFF  → testo principale (bianco un po' lilla)
//   secondary   #9890BF  → testo secondario (date, sottotitoli)
//
//  📌 Nota per me: l'app è solo scura (Info.plist → UIUserInterfaceStyle = Dark),
//  perché tutto il design è pensato su questo sfondo notturno.
//

import SwiftUI

extension Color {
    /// Permette di scrivere i colori come in Sketch: Color(hex: 0x9F7BFF)
    init(hex: UInt32, opacity: Double = 1) {
        // ">> 16" sposta i bit per prendere solo il rosso, "& 0xFF" tiene gli ultimi 8 bit
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {

    // MARK: - Palette Ube night

    static let background = Color(hex: 0x1A1530)
    static let card       = Color(hex: 0x262044)
    static let highlight  = Color(hex: 0x332A5C)
    static let main       = Color(hex: 0x9F7BFF)
    static let lightMain  = Color(hex: 0xCDB9FF)
    static let accent     = Color(hex: 0x7EF0C8)
    static let text       = Color(hex: 0xF1EDFF)
    /// Il grigio-lilla dei testi secondari. Sta in Assets.xcassets ("SecondaryText")
    /// perché lì posso dargli DUE versioni: quella di Sketch (#9890BF) e una più chiara
    /// (#CDC6EC) che iOS usa da solo se l'utente attiva
    /// Impostazioni → Accessibilità → Schermo e dimensioni testo → Aumenta contrasto.
    /// 📌 Nota per me: #9890BF su una card viola chiara (#332A5C) ha un contrasto di 4,35:1,
    /// appena sotto il 4,5:1 consigliato per il testo piccolo. Così chi ne ha bisogno è coperto.
    static let secondary  = Color("SecondaryText")

    /// Arancione tenue solo per gli avvisi (es. "il piano è stretto")
    static let warning    = Color(hex: 0xFFB86B)
    /// Il blu-viola dell'anello grande nella schermata iniziale (00 Start)
    static let ring       = Color(hex: 0x5E60E0)
}

// MARK: - Caratteri
//
// In Sketch il font è Helvetica Neue; su iPhone uso il font di sistema (San Francisco),
// che è quasi uguale e si ingrandisce da solo con le impostazioni di accessibilità.

extension Font {
    /// "Today", "Plan" (34 bold)
    static let dmLargeTitle = Font.system(.largeTitle, weight: .bold)
    /// "New exam", "How do you feel?" (30 bold)
    static let dmTitle      = Font.system(.title, weight: .bold)
    /// "Read Ch. 2" nella card (26 bold)
    static let dmCardTitle  = Font.system(.title2, weight: .bold)
    /// titoli delle righe ("Math", "Ready")
    static let dmRowTitle   = Font.system(.body, weight: .semibold)
    /// "YOUR EXAMS", "TINY STEPS"
    static let dmSection    = Font.system(.footnote, weight: .bold)
    /// testo dei bottoni
    static let dmButton     = Font.system(.body, weight: .bold)
}
