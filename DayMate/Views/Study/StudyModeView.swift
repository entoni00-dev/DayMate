//
//  StudyModeView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  📚 La modalità Studio: la "home" di chi sceglie "Study" nella schermata iniziale.
//
//   [Studio]                     ⚙️ (+)
//   Today
//   Thursday 29 October
//   ( Oggi ) Dubbi  Coach  Progressi
//
//   - Oggi      → prossimo passo, i tuoi esami, il piano di oggi (schermata Today di Sketch)
//   - Dubbi     → le domande parcheggiate
//   - Coach     → consigli dai tuoi dati, Tutor AI, cosa funziona davvero
//   - Progressi → quante volte hai iniziato, minuti, umore prima/dopo
//

import SwiftUI
import SwiftData

/// Le 4 sezioni della modalità Studio
enum StudyTab: String, CaseIterable {
    case today, doubts, coach, progress

    var title: String {
        switch self {
        case .today:    return tr("Today", "Oggi")
        case .doubts:   return tr("Doubts", "Dubbi")
        case .coach:    return "Coach"
        case .progress: return tr("Progress", "Progressi")
        }
    }

    var icon: String {
        switch self {
        case .today:    return "sun.max.fill"
        case .doubts:   return "questionmark.bubble.fill"
        case .coach:    return "sparkles"
        case .progress: return "chart.bar.fill"
        }
    }

    /// La stessa sezione pronta per la barra in alto
    var item: TabItem {
        TabItem(id: rawValue, title: title, icon: icon)
    }
}

struct StudyModeView: View {
    // @Binding = il percorso di navigazione appartiene a RootView
    @Binding var path: NavigationPath

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var tab: StudyTab = .today
    @State private var showingAddExam = false
    @State private var showingAddDoubt = false

    /// Il "+" cambia significato in base alla sezione
    private var addLabel: String? {
        switch tab {
        case .today:          return tr("New exam", "Nuovo esame")
        case .doubts, .coach: return tr("New doubt", "Nuovo dubbio")
        case .progress:       return nil
        }
    }

    /// Sotto "Today" metto la data, come in Sketch ("Thursday 29 October")
    private var subtitle: String? {
        tab == .today ? Date.now.longDayText : nil
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                // .navigationDestination: "quando qualcuno apre un valore di questo tipo, mostra questa vista"
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .settings: SettingsView()
                    }
                }
                .navigationDestination(for: Exam.self) { exam in
                    ExamDetailView(exam: exam)
                }
                .navigationDestination(isPresented: $showingAddExam) {
                    AddExamView()
                }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            SpaceHeader(mode: .study,
                        title: tab.title,
                        subtitle: subtitle,
                        items: StudyTab.allCases.map { $0.item },
                        selectedID: tab.rawValue,
                        onSelect: { id in
                            // dall'id ("today", "doubts"…) ritrovo la sezione
                            if let newTab = StudyTab(rawValue: id) {
                                withAnimation(.snappy) { tab = newTab }
                            }
                        },
                        addLabel: addLabel,
                        onAdd: add)

            // Il contenuto della sezione scelta
            Group {
                switch tab {
                case .today:    TodayView(onAddExam: { showingAddExam = true })
                case .doubts:   DoubtsView(embedded: true)
                case .coach:    CoachView(embedded: true, onOpenDoubts: { tab = .doubts })
                case .progress: StatsView(embedded: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.opacity)
        }
        .dmScreen()
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAddDoubt) {
            AddDoubtSheet()
        }
    }

    private func add() {
        switch tab {
        case .today:          showingAddExam = true
        case .doubts, .coach: showingAddDoubt = true
        case .progress:       break
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    StudyModeView(path: .constant(NavigationPath()))
        .modelContainer(PreviewData.container)
}
