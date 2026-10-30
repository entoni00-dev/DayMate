//
//  SettingsView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Impostazioni minime. Meno opzioni = meno "procrastinazione da configurazione"
//  (sistemare le impostazioni invece di studiare è un classico!).
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    @AppStorage(AppSettings.blockMinutesKey) private var blockMinutes = AppSettings.defaultBlockMinutes
    @AppStorage(AppSettings.shortBreakKey) private var shortBreak = AppSettings.defaultShortBreak
    @AppStorage(AppSettings.longBreakKey) private var longBreak = AppSettings.defaultLongBreak
    @AppStorage(AppSettings.waterGoalKey) private var waterGoal = AppSettings.defaultWaterGoal
    @AppStorage(AppSettings.soundEnabledKey) private var soundEnabled = true
    @AppStorage(AppSettings.notificationsKey) private var notificationsEnabled = true
    @AppStorage(AppSettings.hasSeenOnboardingKey) private var hasSeenOnboarding = true
    @AppStorage(AppMode.storageKey) private var modeRaw = AppMode.study.rawValue
    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var confirmSwitch = false

    // In UserDefaults la modalità è salvata come testo ("study" / "planner"):
    // qui la ritrasformo nell'enum AppMode
    private var mode: AppMode { AppMode(rawValue: modeRaw) ?? .study }
    private var otherMode: AppMode { mode == .study ? .planner : .study }

    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context
    @State private var confirmReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                TopLink(title: mode.title, showsChevron: true)
                ScreenHeader(title: tr("Settings", "Impostazioni"))
            }
            .padding(.horizontal, 24)

            Form {
                // MARK: Modalità
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: mode.icon)
                            .foregroundStyle(Theme.text)
                            .frame(width: 34, height: 34)
                            .background(Theme.highlight, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tr("You're using", "Stai usando"))
                                .font(.caption)
                                .foregroundStyle(Theme.secondary)
                            Text(mode.choiceTitle)
                                .font(.headline)
                        }
                    }
                    Button {
                        confirmSwitch = true
                    } label: {
                        Label(tr("Switch to \(otherMode.title)", "Passa a \(otherMode.title)"),
                              systemImage: "arrow.left.arrow.right")
                    }
                } header: {
                    Text(tr("Mode", "Modalità"))
                } footer: {
                    Text(tr("Your data stays on the phone: exams, doubts and tasks are still there when you come back.",
                            "I tuoi dati restano sul telefono: esami, dubbi e attività ci sono ancora quando torni."))
                }
                .listRowBackground(Theme.card)

                // MARK: Lingua
                Section {
                    HStack {
                        Text(tr("App language", "Lingua dell'app"))
                        Spacer()
                        LanguageToggle()
                    }
                } header: {
                    Text(tr("Language", "Lingua"))
                } footer: {
                    Text(tr("Steps already created stay in the language they were created in.",
                            "I passi già creati restano nella lingua in cui sono stati creati."))
                }
                .listRowBackground(Theme.card)

                if mode == .study {
                    // MARK: Ritmo
                    Section {
                        Picker(tr("Study block", "Blocco di studio"), selection: $blockMinutes) {
                            ForEach([15, 20, 25, 30, 45, 50], id: \.self) { Text("\($0) min").tag($0) }
                        }
                        Picker(tr("Short break", "Pausa breve"), selection: $shortBreak) {
                            ForEach([3, 5, 10], id: \.self) { Text("\($0) min").tag($0) }
                        }
                        Picker(tr("Long break (every 4 blocks)", "Pausa lunga (ogni 4 blocchi)"), selection: $longBreak) {
                            ForEach([10, 15, 20, 30], id: \.self) { Text("\($0) min").tag($0) }
                        }
                    } header: {
                        Text(tr("Study / break rhythm", "Ritmo studio / pausa"))
                    } footer: {
                        Text(tr("The first blocks start shorter depending on how you feel (e.g. 5 → 10 → 15 min if you're stuck) and grow up to this length. 25 + 5 minutes is the classic \"Pomodoro\": a good starting point, not a scientific rule.",
                                "I primi blocchi partono più corti in base a come ti senti (es. 5 → 10 → 15 min se sei bloccato) e crescono fino a questa durata. 25 + 5 minuti è il classico \"Pomodoro\": un buon punto di partenza, non una regola scientifica."))
                    }
                    .listRowBackground(Theme.card)
                }
                if mode == .planner {
                    // MARK: Planner
                    Section(tr("Planner", "Planner")) {
                        Stepper(value: $waterGoal, in: 4...14) {
                            Text(tr("Water goal: \(waterGoal) glasses", "Obiettivo acqua: \(waterGoal) bicchieri"))
                        }
                    }
                    .listRowBackground(Theme.card)
                }
                if mode == .study {
                    // MARK: Avvisi
                    Section {
                        Toggle(tr("Alarm sound", "Suono di sveglia"), isOn: $soundEnabled)
                            .tint(Theme.main)
                        Toggle(tr("Notifications when locked", "Notifiche a schermo bloccato"), isOn: $notificationsEnabled)
                            .tint(Theme.main)
                        Button(tr("Try the break sound", "Prova il suono della pausa")) { SoundPlayer.shared.play(.pause, repeats: 1) }
                        Button(tr("Try the study sound", "Prova il suono dello studio")) { SoundPlayer.shared.play(.study, repeats: 1) }
                    } header: {
                        Text(tr("Alerts", "Avvisi"))
                    } footer: {
                        Text(tr("End of block: \"Time for a break!\". End of break: \"Welcome back!\". The sound plays even with the silent switch on, like an alarm. Notifications are local: no server.",
                                "A fine blocco: \"È tempo di una pausa!\". A fine pausa: \"Bentornato!\". Il suono si sente anche con l'interruttore silenzioso, come una sveglia. Le notifiche sono locali: nessun server."))
                    }
                    .listRowBackground(Theme.card)
                }
                // MARK: Privacy
                Section("Privacy") {
                    Label {
                        Text(tr("All data stays on this iPhone. No account, no server, no tracking. The AI tutor, when available, runs on the phone too.",
                                "Tutti i dati restano solo su questo iPhone. Niente account, niente server, niente tracciamento. Anche il Tutor AI, quando disponibile, gira sul telefono."))
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(Theme.accent)
                    }
                }
                .listRowBackground(Theme.card)

                Section {
                    Button(tr("Back to the start screen", "Torna alla schermata iniziale")) {
                        hasSeenOnboarding = false
                    }
                    Button(tr("Delete all data", "Cancella tutti i dati"), role: .destructive) {
                        confirmReset = true
                    }
                }
                .listRowBackground(Theme.card)

                Section {
                    HStack(spacing: 12) {
                        BlobView(pose: .hello)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("DayMate 2.0")
                                .font(.headline)
                            Text(tr("Apple Foundation Program project.\nChallenge: help students overcome the anxiety of starting and take real breaks instead of scrolling.",
                                    "Progetto per l'Apple Foundation Program.\nChallenge: aiutare gli studenti a superare l'ansia di iniziare e a fare pause vere invece di scrollare."))
                                .font(.caption)
                                .foregroundStyle(Theme.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .tint(Theme.lightMain)
        }
        .dmScreen()
        // .confirmationDialog chiede conferma prima di un'azione che non si può annullare
        .confirmationDialog(tr("Switch to \(otherMode.title)?", "Passare a \(otherMode.title)?"),
                            isPresented: $confirmSwitch,
                            titleVisibility: .visible) {
            Button(tr("Switch", "Passa")) {
                Haptics.success()
                modeRaw = otherMode.rawValue
            }
        } message: {
            Text(otherMode.choiceSubtitle)
        }
        .confirmationDialog(tr("Delete all data?", "Cancellare tutti i dati?"),
                            isPresented: $confirmReset,
                            titleVisibility: .visible) {
            Button(tr("Delete everything", "Cancella tutto"), role: .destructive) { resetAll() }
        } message: {
            Text(tr("Exams, steps, doubts, planner and statistics will be deleted. This can't be undone.",
                    "Esami, passi, dubbi, planner e statistiche verranno eliminati. Non si può annullare."))
        }
    }

    /// Cancella tutto il database locale
    private func resetAll() {
        do {
            try context.delete(model: StudySession.self)
            try context.delete(model: StudyStep.self)
            try context.delete(model: Exam.self)
            try context.delete(model: Doubt.self)
            try context.delete(model: PlannerTask.self)
            try context.delete(model: WaterLog.self)
            try context.save()
            Haptics.success()
        } catch {
            // In un'app vera mostrerei un alert; per il progetto basta il log.
            print("Errore durante il reset: \(error)")
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack { SettingsView() }
        .modelContainer(PreviewData.container)
}
