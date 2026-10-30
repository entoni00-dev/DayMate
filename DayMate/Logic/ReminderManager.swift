//
//  ReminderManager.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🔔 I PROMEMORIA: le notifiche che ti ricordano di fare qualcosa.
//  (Le notifiche del timer, "È tempo di una pausa!", sono un'altra cosa: NotificationManager.)
//
//   📚 Studio      → ogni giorno all'ora scelta: "Il prossimo piccolo passo: Read Ch. 2"
//   🗓️ Impegni     → X minuti prima di ogni impegno del Planner con un orario
//   🚩 Scadenze    → il giorno prima alle 18:00: "Domani: esame di Math"
//   💧 Acqua       → ogni 1/2/3 ore, dalle 9 alle 21
//
//  Tutto si accende, si spegne e si regola in ⚙️ Impostazioni → Promemoria.
//
//  📌 Come funziona: invece di aggiungere e togliere notifiche una alla volta
//  (facile dimenticarsene una!), ogni volta RIFACCIO TUTTO da capo:
//   1. cancello tutti i promemoria vecchi (hanno l'id che inizia con "reminder.")
//   2. li ricreo dai dati di adesso (esami, impegni, impostazioni)
//  Lo faccio quando apri l'app, quando cambiano esami o impegni e quando cambi
//  un'impostazione (vedi RootView e ReminderSettingsView).
//
//  ⚠️ Limite di iOS: un'app può avere al massimo 64 notifiche in attesa.
//  Per questo programmo solo i prossimi 7 giorni di impegni e i prossimi 30 di scadenze.
//

import Foundation
import UserNotifications

final class ReminderManager {
    static let shared = ReminderManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    /// Tutti i promemoria iniziano così: è il modo per riconoscerli e cancellarli
    private let prefix = "reminder."

    /// Rifà tutti i promemoria a partire dagli esami e dagli impegni salvati
    func refresh(exams: [Exam], tasks: [PlannerTask]) {
        // 1. Preparo le nuove notifiche ADESSO (leggo i dati di SwiftData qui, subito)
        var requests: [UNNotificationRequest] = []
        if AppSettings.studyReminderOn { requests.append(studyReminder(exams: exams)) }
        if AppSettings.taskRemindersOn { requests += taskReminders(tasks: tasks) }
        if AppSettings.deadlineRemindersOn { requests += deadlineReminders(exams: exams, tasks: tasks) }
        if AppSettings.waterRemindersOn { requests += waterReminders() }

        // 2. Poi, "in background" (Task + await), cancello le vecchie e aggiungo le nuove
        Task {
            let pending = await center.pendingNotificationRequests()
            let oldIDs = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: oldIDs)
            // prefix(55): resto sotto il limite di 64, lasciando posto a quelle del timer
            for request in requests.prefix(55) {
                try? await center.add(request)
            }
        }
    }

    /// Una notifica di prova tra 5 secondi (per vedere come appare)
    func sendTest() {
        let request = makeRequest(id: "test",
                                  title: tr("👋 Hi from DayMate", "👋 Ciao da DayMate"),
                                  body: tr("This is how your reminders will look.",
                                           "Così appariranno i tuoi promemoria."),
                                  trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        center.add(request) { _ in }
    }

    // MARK: - 📚 Studio

    private func studyReminder(exams: [Exam]) -> UNNotificationRequest {
        // Il passo più vicino da fare (lo stesso del "NEXT TINY STEP" di Today)
        let nextExam = exams
            .filter { !$0.isPast && $0.remainingCount > 0 }
            .sorted { $0.date < $1.date }
            .first

        let body: String
        if let exam = nextExam, let step = exam.nextStep {
            let minutes = exam.estimatedMinutes(for: step)
            body = tr("Next tiny step: \(step.title) (\(exam.name)). Just \(minutes) minutes.",
                      "Il prossimo piccolo passo: \(step.title) (\(exam.name)). Bastano \(minutes) minuti.")
        } else {
            body = tr("Open DayMate and pick one tiny step.", "Apri DayMate e scegli un piccolo passo.")
        }

        // Ora e minuti scelti in Impostazioni (salvati come "minuti dalla mezzanotte")
        let time = AppSettings.studyReminderTime
        var when = DateComponents()
        when.hour = time / 60
        when.minute = time % 60
        // repeats: true = ogni giorno a quell'ora
        return makeRequest(id: "study",
                           title: tr("📚 Time for a tiny step", "📚 È ora di un piccolo passo"),
                           body: body,
                           trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true))
    }

    // MARK: - 🗓️ Impegni del Planner

    private func taskReminders(tasks: [PlannerTask]) -> [UNNotificationRequest] {
        let lead = AppSettings.taskLeadMinutes
        let now = Date()
        let limit = now.addingTimeInterval(7 * 24 * 3600)   // solo i prossimi 7 giorni

        // compactMap = come map, ma butta via i nil (impegni senza orario, già fatti o passati)
        let upcoming: [(task: PlannerTask, fireDate: Date, time: Date)] = tasks.compactMap { task in
            guard !task.isDone, let time = task.time else { return nil }
            let fireDate = time.addingTimeInterval(TimeInterval(-lead * 60))
            guard fireDate > now, fireDate < limit else { return nil }
            return (task, fireDate, time)
        }

        return upcoming
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(35)
            .enumerated()
            .map { index, item in
                let body = lead == 0
                    ? tr("Now · \(item.task.timeText)", "Adesso · \(item.task.timeText)")
                    : tr("In \(lead) minutes · \(item.task.timeText)", "Tra \(lead) minuti · \(item.task.timeText)")
                return makeRequest(id: "task.\(index)",
                                   title: "\(item.task.kind == .study ? "📖" : "⏰") \(item.task.title)",
                                   body: body,
                                   trigger: oneShot(at: item.fireDate))
            }
    }

    // MARK: - 🚩 Scadenze ed esami

    private func deadlineReminders(exams: [Exam], tasks: [PlannerTask]) -> [UNNotificationRequest] {
        let now = Date()
        let limit = now.addingTimeInterval(30 * 24 * 3600)   // solo i prossimi 30 giorni
        var items: [(title: String, day: Date)] = []

        for exam in exams where !exam.isPast {
            items.append((tr("Tomorrow: \(exam.name) exam", "Domani: esame di \(exam.name)"), exam.date))
        }
        for task in tasks where task.isDeadline && !task.isDone {
            items.append((tr("Tomorrow: \(task.title)", "Domani: \(task.title)"), task.day))
        }

        let calendar = Calendar.current
        var requests: [UNNotificationRequest] = []
        for (index, item) in items.enumerated() {
            // il giorno prima, alle 18:00: c'è ancora tempo per prepararsi
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: item.day)),
                  let fireDate = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayBefore),
                  fireDate > now, fireDate < limit else { continue }
            requests.append(makeRequest(id: "deadline.\(index)",
                                        title: "🚩 " + item.title,
                                        body: tr("Open DayMate to see what's left to do.",
                                                 "Apri DayMate per vedere cosa manca."),
                                        trigger: oneShot(at: fireDate)))
        }
        return Array(requests.prefix(10))
    }

    // MARK: - 💧 Acqua

    private func waterReminders() -> [UNNotificationRequest] {
        let every = max(1, AppSettings.waterEveryHours)
        // stride = "da 10 a 21, a passi di `every`": 10, 12, 14… (alle 9 c'è già la colazione)
        return stride(from: 10, through: 21, by: every).map { hour in
            var when = DateComponents()
            when.hour = hour
            when.minute = 0
            return makeRequest(id: "water.\(hour)",
                               title: tr("💧 A glass of water?", "💧 Un bicchiere d'acqua?"),
                               body: tr("Tap the drops in Plan to keep count.",
                                        "Tocca le gocce in Plan per tenere il conto."),
                               trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true))
        }
    }

    // MARK: - Aiutanti

    private func makeRequest(id: String, title: String, body: String,
                             trigger: UNNotificationTrigger) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return UNNotificationRequest(identifier: prefix + id, content: content, trigger: trigger)
    }

    /// Un trigger che scatta una volta sola, a una data precisa
    private func oneShot(at date: Date) -> UNCalendarNotificationTrigger {
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
    }
}
