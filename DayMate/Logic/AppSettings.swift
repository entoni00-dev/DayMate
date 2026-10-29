//
//  AppSettings.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Le chiavi delle impostazioni in un posto solo.
//  Prima le scrivevo a mano ("breakMinutes") in più file: basta un errore di battitura
//  e l'impostazione smette di funzionare senza nessun errore di compilazione.
//  Con le costanti, il compilatore mi protegge.
//

import Foundation

enum AppSettings {
    // Chiavi (usate anche con @AppStorage)
    static let blockMinutesKey       = "blockMinutes"
    static let shortBreakKey         = "shortBreakMinutes"
    static let longBreakKey          = "longBreakMinutes"
    static let soundEnabledKey       = "soundEnabled"
    static let notificationsKey      = "notificationsEnabled"
    static let hasSeenOnboardingKey  = "hasSeenOnboarding"
    static let waterGoalKey          = "waterGoal"

    // Valori di default
    static let defaultBlockMinutes = 25
    static let defaultShortBreak   = 5
    static let defaultLongBreak    = 15
    static let defaultWaterGoal    = 8

    // Lettura comoda fuori dalle viste (dove @AppStorage non c'è)
    private static var defaults: UserDefaults { .standard }

    static var blockMinutes: Int {
        defaults.object(forKey: blockMinutesKey) as? Int ?? defaultBlockMinutes
    }
    static var shortBreak: Int {
        defaults.object(forKey: shortBreakKey) as? Int ?? defaultShortBreak
    }
    static var longBreak: Int {
        defaults.object(forKey: longBreakKey) as? Int ?? defaultLongBreak
    }
    static var soundEnabled: Bool {
        defaults.object(forKey: soundEnabledKey) as? Bool ?? true
    }
    static var waterGoal: Int {
        defaults.object(forKey: waterGoalKey) as? Int ?? defaultWaterGoal
    }
    static var notificationsEnabled: Bool {
        defaults.object(forKey: notificationsKey) as? Bool ?? true
    }
}
