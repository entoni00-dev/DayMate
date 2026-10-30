//
//  StudyModeView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  📚 La modalità Studio: si apre quando nella schermata iniziale tocchi "Study".
//
//   ‹ Home                            (+)
//   Study
//   Thursday 29 October
//   …contenuto della sezione…
//   ─────────────────────────────────────
//    ☀️ Oggi   💬 Dubbi   📊 Progressi   ⚙️ Impostazioni     ← barra in basso (TabView)
//
//   - Oggi         → prossimo passo, i tuoi esami, il piano di oggi (schermata Today di Sketch)
//   - Dubbi        → le domande parcheggiate (con il Tutor AI, se l'iPhone lo supporta)
//   - Progressi    → quante volte hai iniziato, minuti, umore prima/dopo
//   - Impostazioni → ritmo di studio, avvisi, lingua, cambio modalità
//
//  📌 Nota per me: ogni sezione ha la SUA NavigationStack. Così se apro un esame
//  in "Oggi", passo a "Dubbi" e poi torno, ritrovo l'esame aperto (come in Musica o Foto).
//

import SwiftUI
import SwiftData

/// Le 4 sezioni della modalità Studio
enum StudyTab: String, CaseIterable {
    case today, doubts, progress, settings

    var title: String {
        switch self {
        case .today:    return tr("Today", "Oggi")
        case .doubts:   return tr("Doubts", "Dubbi")
        case .progress: return tr("Progress", "Progressi")
        case .settings: return tr("Settings", "Impostazioni")
        }
    }

    var icon: String {
        switch self {
        case .today:    return "sun.max.fill"
        case .doubts:   return "questionmark.bubble.fill"
        case .progress: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct StudyModeView: View {
    // @Binding = la sezione aperta appartiene a RootView: così, se cambio lingua
    // e l'app viene ridisegnata, resto nella stessa sezione
    @Binding var tab: StudyTab
    /// Torna alla schermata iniziale ("Studiare o organizzare la giornata?")
    var onChangeMode: () -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var showingAddExam = false
    @State private var showingAddDoubt = false

    var body: some View {
        // TabView = la barra delle sezioni in basso.
        // selection: $tab → la TabView sa quale sezione è aperta e la cambia quando tocco un'icona
        TabView(selection: $tab) {
            // ☀️ Oggi
            NavigationStack {
                // in Sketch il titolo di questa schermata è "Study" e al posto del "+"
                // c'è il grande bottone "Add an exam" (dentro TodayView)
                section(.today, title: tr("Study", "Studio"), subtitle: Date.now.longDayText) {
                    TodayView(onAddExam: { showingAddExam = true })
                }
                // .navigationDestination: "quando qualcuno apre un valore di questo tipo, mostra questa vista"
                .navigationDestination(for: Exam.self) { exam in
                    ExamDetailView(exam: exam)
                }
                .navigationDestination(isPresented: $showingAddExam) {
                    AddExamView()
                        // mentre scrivo un nuovo esame la barra in basso sparisce: meno distrazioni
                        .toolbar(.hidden, for: .tabBar)
                }
            }
            .tabItem { Label(StudyTab.today.title, systemImage: StudyTab.today.icon) }
            .tag(StudyTab.today)

            // 💬 Dubbi
            NavigationStack {
                section(.doubts, addLabel: tr("New doubt", "Nuovo dubbio"), onAdd: { showingAddDoubt = true }) {
                    DoubtsView(embedded: true)
                }
            }
            .tabItem { Label(StudyTab.doubts.title, systemImage: StudyTab.doubts.icon) }
            .tag(StudyTab.doubts)

            // 📊 Progressi
            NavigationStack {
                section(.progress) {
                    StatsView(embedded: true)
                }
            }
            .tabItem { Label(StudyTab.progress.title, systemImage: StudyTab.progress.icon) }
            .tag(StudyTab.progress)

            // ⚙️ Impostazioni
            NavigationStack {
                SettingsView(mode: .study, onChangeMode: onChangeMode)
                    .dmTabBar()
            }
            .tabItem { Label(StudyTab.settings.title, systemImage: StudyTab.settings.icon) }
            .tag(StudyTab.settings)
        }
        // la sezione scelta nella barra è viola
        .tint(Theme.main)
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAddDoubt) {
            AddDoubtSheet()
        }
    }

    /// Una sezione: intestazione in alto + il suo contenuto.
    /// 📌 @ViewBuilder mi permette di passare il contenuto tra parentesi graffe { … },
    /// come si fa con VStack o NavigationStack.
    private func section<Content: View>(_ tab: StudyTab,
                                        title: String? = nil,
                                        subtitle: String? = nil,
                                        addLabel: String? = nil,
                                        onAdd: @escaping () -> Void = {},
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            // title ?? tab.title = "usa il titolo che mi passi, altrimenti il nome della sezione"
            ModeHeader(onHome: onChangeMode, title: title ?? tab.title, subtitle: subtitle,
                       addLabel: addLabel, onAdd: onAdd)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .dmScreen()
        .dmTabBar()
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    StudyModeView(tab: .constant(.today), onChangeMode: {})
        .modelContainer(PreviewData.container)
}
