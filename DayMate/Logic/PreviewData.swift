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
            for: Exam.self, StudyStep.self, StudySession.self, Doubt.self, PlannerTask.self, WaterLog.self,
            configurations: config
        )
        let context = container.mainContext

        let analisi = Exam(name: "Math",
                           date: Calendar.current.date(byAdding: .day, value: 9, to: .now) ?? .now,
                           emoji: "🧮", colorIndex: 0, kind: .mixed, dailyMinutes: 120)
        context.insert(analisi)
        analisi.steps.append(contentsOf: StepGenerator.makePlan(topics: [
            TopicDraft(name: "Limiti", pages: 18, difficulty: .medium),
            TopicDraft(name: "Derivate", pages: 24, difficulty: .hard),
            TopicDraft(name: "Integrali", pages: 20, difficulty: .hard),
        ], kind: .mixed))
        // Qualche passo già fatto (con tempi misurati), per vedere progressi e calibrazione
        for step in analisi.sortedSteps.prefix(5) {
            step.isDone = true
            step.actualSeconds = step.minutes * 60 * 8 / 10
        }

        let storia = Exam(name: "Physics",
                          date: Calendar.current.date(byAdding: .day, value: 23, to: .now) ?? .now,
                          emoji: "🌍", colorIndex: 3, kind: .theory, dailyMinutes: 90)
        context.insert(storia)
        storia.steps.append(contentsOf: StepGenerator.makePlan(topics: [
            TopicDraft(name: "Prima guerra mondiale", pages: 30, difficulty: .easy),
            TopicDraft(name: "Il dopoguerra", pages: 25, difficulty: .medium),
        ], kind: .theory))

        // Una sessione di esempio (stressato → alla grande)
        let session = StudySession(moodBefore: .stressed)
        session.moodAfterRaw = Mood.great.rawValue
        session.focusedSeconds = 40 * 60
        session.stepsCompleted = 5
        session.blocks = 3
        session.realBreaks = 2
        context.insert(session)
        session.exam = analisi

        // Un dubbio parcheggiato
        context.insert(Doubt(text: "Perché il limite di sin(x)/x fa 1?", topic: "Limiti", examName: "Math"))

        // Planner: due cose da fare e 5 bicchieri d'acqua
        context.insert(PlannerTask(title: "Buy a new notebook", day: .now))
        context.insert(PlannerTask(title: "Call Giulia about the notes", day: .now))
        context.insert(WaterLog(day: .now, glasses: 5))

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
