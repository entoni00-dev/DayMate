//
//  PreviewData.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Dati finti SOLO per le #Preview di Xcode.
//  Uso un database in memoria (isStoredInMemoryOnly) così le preview
//  non sporcano i dati veri e partono sempre pulite.
//

import Foundation
import SwiftData

@MainActor
enum PreviewData {

    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // try! va bene SOLO qui: se fallisce in preview voglio saperlo subito.
        let container = try! ModelContainer(
            for: Exam.self, StudyStep.self, StudySession.self, PlannerTask.self, WaterLog.self,
            configurations: config
        )
        let context = container.mainContext

        // Gli stessi esami delle schermate di Sketch: Math (6 passi) e Physics (5 passi)
        let math = Exam(name: "Math",
                        date: Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now,
                        emoji: "🧮", colorIndex: 0, kind: .mixed, dailyMinutes: 60)
        context.insert(math)
        let mathSteps = ["Read notes Ch. 1", "Exercises 1–5", "Read Ch. 2",
                         "Exercises 6–10", "Mock test", "Review mistakes"]
        for (index, title) in mathSteps.enumerated() {
            let step = StudyStep(title: title, topic: "Math", minutes: 15, order: index, kind: .custom)
            step.isDone = index < 2          // i primi 2 sono già fatti
            math.steps.append(step)
        }

        let physics = Exam(name: "Physics",
                           date: Calendar.current.date(byAdding: .day, value: 22, to: .now) ?? .now,
                           emoji: "⚛️", colorIndex: 3, kind: .theory, dailyMinutes: 60)
        context.insert(physics)
        for (index, title) in ["Read Ch. 1", "Formulas sheet", "Exercises 1–4", "Read Ch. 2", "Mock test"].enumerated() {
            let step = StudyStep(title: title, topic: "Physics", minutes: 15, order: index, kind: .custom)
            step.isDone = index < 1
            physics.steps.append(step)
        }

        // Una sessione di esempio (stressato → alla grande)
        let session = StudySession(moodBefore: .stressed)
        session.moodAfterRaw = Mood.ready.rawValue
        session.focusedSeconds = 40 * 60
        session.stepsCompleted = 5
        session.blocks = 3
        session.realBreaks = 2
        context.insert(session)
        session.exam = math


        // Planner: due cose da fare e 5 bicchieri d'acqua
        // (bySettingHour crea "oggi alle 15:00")
        let calendar = Calendar.current
        context.insert(PlannerTask(title: "Lab report", day: .now, kind: .duty,
                                   time: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: .now)))
        context.insert(PlannerTask(title: "Gym", day: .now, kind: .free,
                                   time: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: .now), durationMinutes: 60))
        context.insert(PlannerTask(title: "Dinner with friends", day: .now, kind: .free,
                                   time: calendar.date(bySettingHour: 20, minute: 30, second: 0, of: .now), durationMinutes: 90))
        context.insert(WaterLog(day: .now, glasses: 4))

        return container
    }()

    /// Il primo esame, comodo per le preview delle schermate di dettaglio
    static var sampleExam: Exam {
        let exams = (try? container.mainContext.fetch(FetchDescriptor<Exam>())) ?? []
        return exams.first ?? Exam(name: "Demo", date: .now, emoji: "📘", colorIndex: 1, kind: .mixed, dailyMinutes: 60)
    }

    /// Una sessione di esempio, per la preview del riepilogo
    static var sampleSession: StudySession {
        let sessions = (try? container.mainContext.fetch(FetchDescriptor<StudySession>())) ?? []
        return sessions.first ?? StudySession(moodBefore: .stressed)
    }
}
