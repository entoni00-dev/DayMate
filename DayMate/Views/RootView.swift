//
//  RootView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La vista "radice": la barra delle sezioni in basso, UNA sola per tutta l'app.
//
//   ┌───────────────────────────────────────────┐
//   │  🏠 Home                                   │
//   │     schermata iniziale: Study / Plan my day│
//   │       ├─ Study → Today (‹ Home)            │
//   │       └─ Plan  → Plan  (‹ Home)            │
//   ├───────────────────────────────────────────┤
//   │ 🏠 Home  💬 Dubbi  📊 Progressi  ⚙️ Impost. │   ← TabView di Apple
//   └───────────────────────────────────────────┘
//
//  Ogni volta che apri l'app parti dalla Home: la domanda "studiare o organizzare
//  la giornata?" è la prima cosa che vedi. Dubbi, Progressi e Impostazioni invece
//  sono sempre a un tocco, qualunque cosa tu stia facendo.
//
//  📌 Nota per me: se esco dall'app con il tasto Home e rientro subito, iOS la tiene
//  ancora aperta in memoria e ritrovo la schermata dov'ero. Ed è giusto: se stavo
//  usando il timer di studio, non voglio ritrovarmi alla schermata iniziale.
//

import SwiftUI
import SwiftData

/// Le 4 sezioni della barra in basso
enum AppTab: String, CaseIterable {
    case home, doubts, progress, settings

    var title: String {
        switch self {
        case .home:     return "Home"
        case .doubts:   return tr("Doubts", "Dubbi")
        case .progress: return tr("Progress", "Progressi")
        case .settings: return tr("Settings", "Impostazioni")
        }
    }

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .doubts:   return "questionmark.bubble.fill"
        case .progress: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct RootView: View {
    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    /// La sezione aperta nella barra
    @State private var tab: AppTab = .home
    /// Il percorso dentro la Home (vuoto = schermata iniziale; [study] = dentro Study…)
    @State private var homePath = NavigationPath()
    /// Giorno / Settimana / Scadenze dentro Plan
    @State private var plannerTab: PlannerTab = .day
    @State private var showingAddDoubt = false
    // 📌 Stanno QUI e non nelle viste figlie perché quando cambi lingua l'app viene
    // ridisegnata da capo (vedi .id(language)): così resti dove eri.

    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    /// La lingua scelta dall'utente (di default italiano)
    @AppStorage(L10n.languageKey) private var language = AppLanguage.italian.rawValue

    // @Query legge i dati salvati con SwiftData: servono per i promemoria
    @Query private var exams: [Exam]
    @Query private var tasks: [PlannerTask]
    /// scenePhase dice se l'app è aperta (.active), in background o in passaggio
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // TabView = la barra delle sezioni in basso.
        // selection: $tab → la TabView sa quale sezione è aperta e la cambia quando tocco un'icona
        TabView(selection: $tab) {
            // 🏠 Home
            NavigationStack(path: $homePath) {
                OnboardingView { chosen in
                    // aggiungere la modalità al percorso = "apri quella schermata sopra la Home"
                    homePath.append(chosen)
                }
                .dmScreen()
                .dmTabBar()
                // .navigationDestination: "quando qualcuno apre un valore di questo tipo, mostra questa vista"
                .navigationDestination(for: AppMode.self) { mode in
                    switch mode {
                    case .study:   StudyHomeView()
                    case .planner: PlannerHomeView(tab: $plannerTab)
                    }
                }
                .navigationDestination(for: Exam.self) { exam in
                    ExamDetailView(exam: exam)
                }
            }
            .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
            .tag(AppTab.home)

            // 💬 Dubbi
            NavigationStack {
                tabScreen(title: AppTab.doubts.title,
                          addLabel: tr("New doubt", "Nuovo dubbio"),
                          onAdd: { showingAddDoubt = true }) {
                    DoubtsView(embedded: true)
                }
            }
            .tabItem { Label(AppTab.doubts.title, systemImage: AppTab.doubts.icon) }
            .tag(AppTab.doubts)

            // 📊 Progressi
            NavigationStack {
                tabScreen(title: AppTab.progress.title) {
                    StatsView(embedded: true)
                }
            }
            .tabItem { Label(AppTab.progress.title, systemImage: AppTab.progress.icon) }
            .tag(AppTab.progress)

            // ⚙️ Impostazioni
            NavigationStack {
                SettingsView()
                    .dmTabBar()
            }
            .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }
            .tag(AppTab.settings)
        }
        // la sezione scelta nella barra è viola
        .tint(Theme.main)
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAddDoubt) {
            AddDoubtSheet()
        }
        // Quando cambia la lingua ricreo tutte le viste: così ogni tr("…", "…") viene rifatto
        .id(language)
        // Date, DatePicker ecc. nella stessa lingua dei testi
        .environment(\.locale, AppLanguage(rawValue: language)?.locale ?? L10n.locale)
        // Il design Ube night è solo scuro
        .preferredColorScheme(.dark)
        // 🔔 Promemoria sempre aggiornati:
        //  - quando apro l'app (così il "prossimo passo" nel promemoria è quello giusto)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshReminders() }
        }
        //  - quando cambiano esami o impegni (ne aggiungo uno, lo segno fatto…)
        .onChange(of: remindersKey) { _, _ in refreshReminders() }
        //  - e la prima volta che compare
        .onAppear(perform: refreshReminders)
    }

    /// Una sezione semplice della barra: intestazione + contenuto
    private func tabScreen<Content: View>(title: String,
                                          addLabel: String? = nil,
                                          onAdd: @escaping () -> Void = {},
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            ModeHeader(title: title, addLabel: addLabel, onAdd: onAdd)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .dmScreen()
        .dmTabBar()
    }

    // MARK: - Promemoria

    /// Una "impronta" dei dati che contano per i promemoria: se cambia, li rifaccio.
    /// 📌 È una stringa con quanti esami, passi fatti, impegni e impegni fatti ci sono,
    /// più gli orari: basta che cambi una di queste cose e la stringa è diversa.
    private var remindersKey: String {
        let doneSteps = exams.reduce(0) { $0 + $1.doneCount }
        let doneTasks = tasks.filter(\.isDone).count
        let times = tasks.compactMap { $0.time?.timeIntervalSince1970 }.reduce(0, +)
        return "\(exams.count)-\(doneSteps)-\(tasks.count)-\(doneTasks)-\(Int(times))"
    }

    private func refreshReminders() {
        ReminderManager.shared.refresh(exams: exams, tasks: tasks)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
