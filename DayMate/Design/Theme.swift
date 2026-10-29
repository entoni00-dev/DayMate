//
//  Theme.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Colori e caratteri presi dalle schermate di Sketch, in un posto solo.
//
//  🎨 La palette DayMate:
//   - honey  (giallo miele)  → studio, card principali, bottoni secondari
//   - cocoa  (marrone scuro) → bottoni principali ("Start", "Save", "Next")
//   - rust   (ruggine)       → piccole etichette sopra i titoli ("Math - step 3 of 6")
//   - lilac  (lilla)         → tutto ciò che è "Plan"
//   - sky    (azzurrino)     → acqua
//   - cream / paper          → sfondi caldi, mai bianco "da ufficio"
//
//  L'app è solo in modalità chiara (Info.plist → UIUserInterfaceStyle = Light):
//  la palette di Sketch è pensata per sfondi chiari.
//

import SwiftUI

extension Color {
    /// Color(hex: 0xFEB727)
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

enum Theme {

    // MARK: - Palette (campionata dagli screenshot di Sketch)

    static let honey     = Color(hex: 0xFEB727)
    static let honeySoft = Color(hex: 0xFFE9B8)
    static let cocoa     = Color(hex: 0x4F4840)
    static let ink       = Color(hex: 0x4C453D)
    static let rust      = Color(hex: 0x9A4D2F)
    static let cream     = Color(hex: 0xFEFBF2)
    static let paper     = Color(hex: 0xF8F8F8)
    static let stone     = Color(hex: 0xE9E5DA)
    static let sand      = Color(hex: 0xEFE7DA)
    static let mute      = Color(hex: 0x8B8177)
    static let lilac     = Color(hex: 0xD9AAD6)
    static let lilacSoft = Color(hex: 0xEED9EC)
    static let skySoft   = Color(hex: 0xDDE8EE)
    static let water     = Color(hex: 0x8DC1D7)
    static let leaf      = Color(hex: 0x7A886E)
    static let blush     = Color(hex: 0xF1B39C)
    static let pillGray  = Color(hex: 0xF1F1EE)

    /// Colore "di accento" di un esame. In Sketch gli esami sono tutti color miele.
    static let exam = honey

    /// Emoji degli esami (usate nelle statistiche)
    static let emojis = ["📘", "🧮", "💻", "⚙️", "🧪", "🧠", "📐", "🌍", "⚖️", "🎨", "🩺", "📊"]
}

// MARK: - Caratteri
//
// Uso gli stili di testo di sistema (.title, .body…) così il testo si ingrandisce
// con le impostazioni di accessibilità (Dynamic Type).

extension Font {
    static let dmHuge       = Font.system(.largeTitle, weight: .bold)
    static let dmTitle      = Font.system(.title, weight: .bold)
    static let dmTitle2     = Font.system(.title2, weight: .bold)
    static let dmEyebrow    = Font.system(.title3, weight: .medium)
    static let dmHeadline   = Font.system(.headline, weight: .semibold)
    static let dmButton     = Font.system(.body, weight: .medium)
    static let dmSerif      = Font.system(.subheadline, design: .serif, weight: .semibold)
    static let dmSerifBig   = Font.system(.headline, design: .serif, weight: .bold)
}
