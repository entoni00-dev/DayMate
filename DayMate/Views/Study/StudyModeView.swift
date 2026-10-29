//
//  StudyModeView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  📚 La modalità "Organizza lo studio": tutto ciò che serve per preparare gli esami,
//  raccolto sotto una barra in alto. È la "home" di chi sceglie Studio all'inizio.
//
//   [ Esami ] [ Dubbi ] [ Coach ] [ Progressi ]        + (aggiungi, se ha senso)
//
//   - Esami     → i tuoi esami, il piano e "Prossimo piccolo passo" (la sessione)
//   - Dubbi     → le domande parcheggiate, con "+ Dubbio" per aggiungerne quando vuoi
//   - Coach     → consigli dai tuoi dati, Tutor AI, cosa funziona davvero
//   - Progressi → quante volte hai iniziato, minuti, umore prima/dopo
//

import SwiftUI
import SwiftData

/// Le 4 sezioni della modalità Studio
enum StudyTab: String, CaseIterable {
    case exams, doubts, coach, progress

    var title: String {
        switch self {
        case .exams:    return tr("Exams", "Esami")
        case .doubts:   return tr("Doubts", "Dubbi")
        case .coach:    return "Coach"
        case .progress: return tr("Progress", "Progressi")
        }
    }

    var icon: String {
        switch self {
        case .exams:    return "books.vertical.fill"
        case .doubts:   return "bubble.left.and.exclamationmark.bubble.right.fill"
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
    /// Il percorso di navigazione (tenuto in RootView)
    @Binding var path: NavigationPath

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var tab: StudyTab = .exams
    @State private var showingAddExam = false
    @State private var showingAddDoubt = false

    /// Il bottone "+" cambia in base alla sezione
    private var addLabel: String? {
        switch tab {
        case .exams:  return tr("Exam", "Esame")
        case .doubts, .coach: return tr("Doubt", "Dubbio")
        case .progress: return nil
        }
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
                        items: StudyTab.allCases.map { $0.item },
                        selectedID: tab.rawValue,
                        onSelect: { id in
                            // dall'id ("exams", "doubts"…) ritrovo la sezione
                            if let newTab = StudyTab(rawValue: id) {
                                // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                                withAnimation(.snappy) { tab = newTab }
                            }
                        },
                        addLabel: addLabel,
                        onAdd: add)

            Group {
                switch tab {
                case .exams:    ExamsView(embedded: true)
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
        case .exams:          showingAddExam = true
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
