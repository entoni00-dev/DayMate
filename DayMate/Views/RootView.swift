//
//  RootView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La vista "radice": la barra delle sezioni in basso.
//
//  🧭 La barra ha SEMPRE la Home all'inizio e le Impostazioni alla fine.
//  In mezzo ci sono le sezioni della modalità scelta (come entrare "da utente" o "da titolare"):
//
//   📚 STUDIO   🏠 Home · 📊 Progressi · ⚙️ Impostazioni
//   🗓️ PLANNER  🏠 Home · ✅ Giorno · 📅 Settimana · 🚩 Scadenze · ⚙️ Impostazioni
//
//  🏠 Home = la schermata iniziale "Study / Plan my day". Ogni volta che apri l'app
//  parti da qui:
//   - "Study" apre la schermata di oggi SOPRA la Home (con "‹ Home" per tornare)
//     e la barra diventa quella dello Studio (3 bottoni)
//   - "Plan my day" apre la sezione Giorno e la barra diventa quella del Planner
//
//  📌 Nota per me: se esco dall'app con il tasto Home e rientro subito, iOS la tiene
//  ancora aperta in memoria e ritrovo la schermata dov'ero. Ed è giusto: se stavo
//  usando il timer di studio, non voglio ritrovarmi alla schermata iniziale.
//

import SwiftUI
import SwiftData

/// Tutte le sezioni possibili della barra (quali si vedono dipende dalla modalità)
enum AppTab: Hashable {
    case home
    case progress                         // 📚 Studio (la schermata di oggi si apre dalla Home)
    case day, week, deadlines             // 🗓️ Planner
    case settings

    var title: String {
        switch self {
        case .home:      return "Home"
        case .progress:  return tr("Progress", "Progressi")
        case .day:       return tr("Day", "Giorno")
        case .week:      return tr("Week", "Settimana")
        case .deadlines: return tr("Deadlines", "Scadenze")
        case .settings:  return tr("Settings", "Impostazioni")
        }
    }

    var icon: String {
        switch self {
        case .home:      return "house.fill"
        case .progress:  return "chart.bar.fill"
        case .day:       return "checklist"
        case .week:      return "calendar"
        case .deadlines: return "flag.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

struct RootView: View {
    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    /// La sezione aperta: all'apertura dell'app è sempre la Home
    @State private var tab: AppTab = .home
    /// Le schermate aperte sopra la Home (vuoto = la scelta Study / Plan my day)
    @State private var homePath = NavigationPath()
    /// Il giorno scelto nel Planner (condiviso da Giorno, Settimana e Scadenze)
    @State private var plannerDay = Calendar.current.startOfDay(for: .now)
    @State private var showingAddTask = false
    // 📌 Stanno QUI e non nelle viste figlie perché quando cambi lingua l'app viene
    // ridisegnata da capo (vedi .id(language)): così resti dove eri.

    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    /// L'ultima modalità scelta: decide quali sezioni ci sono nella barra mentre sei in Home
    @AppStorage(AppMode.storageKey) private var modeRaw = AppMode.study.rawValue
    /// La lingua scelta dall'utente (di default italiano)
    @AppStorage(L10n.languageKey) private var language = AppLanguage.italian.rawValue

    // @Query legge i dati salvati con SwiftData: servono per i promemoria
    @Query private var exams: [Exam]
    @Query private var tasks: [PlannerTask]
    /// scenePhase dice se l'app è aperta (.active), in background o in passaggio
    @Environment(\.scenePhase) private var scenePhase

    private var mode: AppMode { AppMode(rawValue: modeRaw) ?? .study }

    var body: some View {
        // TabView = la barra delle sezioni in basso.
        // selection: $tab → la TabView sa quale sezione è aperta e la cambia quando tocco un'icona
        TabView(selection: $tab) {
            homeTab

            // Le sezioni in mezzo cambiano con la modalità
            if mode == .study {
                progressTab
            } else {
                dayTab
                weekTab
                deadlinesTab
            }

            settingsTab
        }
        // la sezione scelta nella barra è viola
        .tint(Theme.main)
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAddTask) {
            AddTaskSheet(day: plannerDay, isDeadline: tab == .deadlines)
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

    // MARK: - 🏠 Home

    private var homeTab: some View {
        // NavigationStack(path:) = una pila di schermate; homePath dice quali sono aperte
        NavigationStack(path: $homePath) {
            OnboardingView(currentMode: mode) { chosen in
                // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                withAnimation(.easeInOut) {
                    modeRaw = chosen.rawValue
                }
                if chosen == .study {
                    // aggiungere .study alla pila = "apri la schermata di oggi sopra la Home"
                    homePath.append(AppMode.study)
                } else {
                    tab = .day
                }
            }
            .dmScreen()
            .dmTabBar()
            // .navigationDestination: "quando qualcuno apre un valore di questo tipo, mostra questa vista"
            .navigationDestination(for: AppMode.self) { _ in
                // "‹ Home" svuota la pila: si torna alla scelta
                StudyHomeView(onHome: { homePath = NavigationPath() })
            }
            .navigationDestination(for: Exam.self) { exam in
                ExamDetailView(exam: exam)
            }
        }
        .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
        .tag(AppTab.home)
    }

    // MARK: - 📚 Studio

    private var progressTab: some View {
        NavigationStack {
            screen(title: AppTab.progress.title) {
                StatsView(embedded: true)
            }
        }
        .tabItem { Label(AppTab.progress.title, systemImage: AppTab.progress.icon) }
        .tag(AppTab.progress)
    }

    // MARK: - 🗓️ Planner

    private var dayTab: some View {
        NavigationStack {
            // la schermata "Plan" di Sketch: ‹ Home, il "+" e il titolo "Plan"
            screen(title: tr("Plan", "Pianifica"), onHome: goHome,
                   addLabel: tr("Add to your day", "Aggiungi alla giornata"),
                   onAdd: { showingAddTask = true }) {
                PlannerView(day: $plannerDay)
            }
            .navigationDestination(for: Exam.self) { exam in
                ExamDetailView(exam: exam)
            }
        }
        .tabItem { Label(AppTab.day.title, systemImage: AppTab.day.icon) }
        .tag(AppTab.day)
    }

    private var weekTab: some View {
        NavigationStack {
            screen(title: AppTab.week.title,
                   addLabel: tr("Add to your day", "Aggiungi alla giornata"),
                   onAdd: { showingAddTask = true }) {
                PlannerWeekView(day: $plannerDay) { chosen in
                    // tocco un giorno → lo apro nella sezione "Giorno"
                    plannerDay = chosen
                    tab = .day
                }
            }
        }
        .tabItem { Label(AppTab.week.title, systemImage: AppTab.week.icon) }
        .tag(AppTab.week)
    }

    private var deadlinesTab: some View {
        NavigationStack {
            screen(title: AppTab.deadlines.title,
                   addLabel: tr("Add a deadline", "Aggiungi una scadenza"),
                   onAdd: { showingAddTask = true }) {
                PlannerDeadlinesView()
            }
            .navigationDestination(for: Exam.self) { exam in
                ExamDetailView(exam: exam)
            }
        }
        .tabItem { Label(AppTab.deadlines.title, systemImage: AppTab.deadlines.icon) }
        .tag(AppTab.deadlines)
    }

    // MARK: - ⚙️ Impostazioni

    private var settingsTab: some View {
        NavigationStack {
            SettingsView(mode: mode)
                .dmTabBar()
        }
        .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }
        .tag(AppTab.settings)
    }

    // MARK: - Pezzi in comune

    /// Una sezione: intestazione (‹ Home, titolo, +) + il suo contenuto
    private func screen<Content: View>(title: String,
                                       onHome: (() -> Void)? = nil,
                                       addLabel: String? = nil,
                                       onAdd: @escaping () -> Void = {},
                                       @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            ModeHeader(onHome: onHome, title: title, addLabel: addLabel, onAdd: onAdd)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .dmScreen()
        .dmTabBar()
    }

    /// "‹ Home" nel Planner: apre la prima sezione della barra (e chiude Study, se era aperto)
    private func goHome() {
        homePath = NavigationPath()
        withAnimation(.easeInOut) { tab = .home }
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
