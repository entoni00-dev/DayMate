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
    static let waterGoalKey          = "waterGoal"

    // 🔔 Promemoria (vedi ReminderManager.swift e ReminderSettingsView.swift)
    static let studyReminderOnKey    = "studyReminderOn"
    static let studyReminderTimeKey  = "studyReminderTime"    // minuti dalla mezzanotte (17:00 = 1020)
    static let taskRemindersOnKey    = "taskRemindersOn"
    static let taskLeadMinutesKey    = "taskLeadMinutes"      // quanti minuti prima dell'impegno
    static let deadlineRemindersOnKey = "deadlineRemindersOn"
    static let waterRemindersOnKey   = "waterRemindersOn"
    static let waterEveryHoursKey    = "waterEveryHours"

    // Valori di default
    static let defaultBlockMinutes = 25
    static let defaultShortBreak   = 5
    static let defaultLongBreak    = 15
    static let defaultWaterGoal    = 8
    static let defaultStudyReminderTime = 17 * 60   // 17:00
    static let defaultTaskLeadMinutes   = 10
    static let defaultWaterEveryHours   = 2

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

    // MARK: Promemoria
    // 📌 "?? true": se l'utente non ha mai toccato l'impostazione, vale il valore di default.
    // Studio, impegni e scadenze partono ACCESI (sono il cuore dei promemoria),
    // l'acqua parte SPENTA (è più invadente: tanti avvisi al giorno).
    static var studyReminderOn: Bool {
        defaults.object(forKey: studyReminderOnKey) as? Bool ?? true
    }
    static var studyReminderTime: Int {
        defaults.object(forKey: studyReminderTimeKey) as? Int ?? defaultStudyReminderTime
    }
    static var taskRemindersOn: Bool {
        defaults.object(forKey: taskRemindersOnKey) as? Bool ?? true
    }
    static var taskLeadMinutes: Int {
        defaults.object(forKey: taskLeadMinutesKey) as? Int ?? defaultTaskLeadMinutes
    }
    static var deadlineRemindersOn: Bool {
        defaults.object(forKey: deadlineRemindersOnKey) as? Bool ?? true
    }
    static var waterRemindersOn: Bool {
        defaults.object(forKey: waterRemindersOnKey) as? Bool ?? false
    }
    static var waterEveryHours: Int {
        defaults.object(forKey: waterEveryHoursKey) as? Int ?? defaultWaterEveryHours
    }
}
