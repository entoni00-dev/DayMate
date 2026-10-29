//
//  NotificationManager.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Notifiche LOCALI (nessun server, nessun push remoto).
//
//  È un piccolo paradosso dell'app: è un'app sul telefono che ti chiede di NON usare
//  il telefono. Con le notifiche puoi bloccare lo schermo e metterlo via: quando il
//  blocco finisce arriva "⏸️ È TEMPO DI UNA PAUSA", quando la pausa finisce
//  "▶️ ORA SI TORNA A STUDIARE", ognuna con il suo suono.
//

import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // Identificativi fissi: così posso cancellare la notifica giusta
    static let focusID = "daymate.focus"
    static let breakID = "daymate.break"

    private let center = UNUserNotificationCenter.current()

    /// Chiede il permesso (una sola volta: iOS ricorda la risposta)
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Programma una notifica tra `seconds` secondi, con un suono personalizzato
    func schedule(id: String, title: String, body: String, after seconds: TimeInterval, sound: AlarmSound? = nil) {
        guard AppSettings.notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let sound, AppSettings.soundEnabled {
            // Il file deve essere nel bundle dell'app, in formato wav/aiff/caf e sotto i 30 secondi
            content.sound = UNNotificationSound(named: UNNotificationSoundName(sound.fileName))
        } else {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { _ in }
    }

    // MARK: - Scorciatoie con le frasi dell'app

    func scheduleBreakTime(after seconds: TimeInterval, studiedMinutes: Int, breakMinutes: Int) {
        schedule(id: Self.focusID,
                 title: tr("⏸️ Time for a break!", "⏸️ È TEMPO DI UNA PAUSA"),
                 body: tr("You studied for \(studiedMinutes) minutes. Now \(breakMinutes) minutes away from the screen.",
                          "Hai studiato \(studiedMinutes) minuti. Ora \(breakMinutes) minuti lontano dallo schermo."),
                 after: seconds, sound: .pause)
    }

    func scheduleBackToStudy(after seconds: TimeInterval) {
        schedule(id: Self.breakID,
                 title: tr("▶️ Break over: welcome back!", "▶️ ORA SI TORNA A STUDIARE"),
                 body: tr("Pick up where you left off: one tiny step at a time.",
                          "Riprendi da dove eri rimasto: un passo alla volta."),
                 after: seconds, sound: .study)
    }

    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.focusID, Self.breakID])
    }
}
