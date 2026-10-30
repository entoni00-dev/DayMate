//
//  ReminderSettingsView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🔔 Impostazioni → Promemoria: l'utente decide QUALI notifiche ricevere e QUANDO.
//
//   STUDIO      [✓] Promemoria per studiare      Ora: 17:00
//   PLANNER     [✓] Avvisi per gli impegni       Quanto prima: 10 min
//   SCADENZE    [✓] Il giorno prima, alle 18:00
//   ACQUA       [ ] Promemoria per bere          Ogni: 2 ore
//               [ Prova una notifica ]
//
//  Ogni volta che cambio qualcosa, chiamo ReminderManager.refresh(): rifà i promemoria
//  con le nuove impostazioni.
//
//  📌 Il permesso: se l'utente ha detto "Non consentire" alle notifiche, l'app NON può
//  richiederlo una seconda volta (lo decide iOS). Posso solo spiegarglielo e portarlo
//  nelle Impostazioni dell'iPhone con un bottone.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ReminderSettingsView: View {
    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    @AppStorage(AppSettings.studyReminderOnKey) private var studyOn = true
    @AppStorage(AppSettings.studyReminderTimeKey) private var studyTime = AppSettings.defaultStudyReminderTime
    @AppStorage(AppSettings.taskRemindersOnKey) private var tasksOn = true
    @AppStorage(AppSettings.taskLeadMinutesKey) private var leadMinutes = AppSettings.defaultTaskLeadMinutes
    @AppStorage(AppSettings.deadlineRemindersOnKey) private var deadlinesOn = true
    @AppStorage(AppSettings.waterRemindersOnKey) private var waterOn = false
    @AppStorage(AppSettings.waterEveryHoursKey) private var waterEvery = AppSettings.defaultWaterEveryHours

    // @Query legge i dati salvati con SwiftData (servono per rifare i promemoria)
    @Query private var exams: [Exam]
    @Query private var tasks: [PlannerTask]

    /// Lo stato del permesso per le notifiche (nil = lo sto ancora controllando)
    @State private var permission: UNAuthorizationStatus?
    @State private var testSent = false

    // openURL apre un link: lo uso per aprire le Impostazioni dell'iPhone
    @Environment(\.openURL) private var openURL

    /// 📌 Il DatePicker vuole una Date, ma io salvo l'ora come numero (minuti dalla mezzanotte).
    /// Questo Binding "traduce" nei due sensi: get = numero → Date, set = Date → numero.
    private var studyTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: studyTime / 60, minute: studyTime % 60,
                                      second: 0, of: .now) ?? .now
            },
            set: { newDate in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                studyTime = (parts.hour ?? 17) * 60 + (parts.minute ?? 0)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                TopLink(title: tr("Settings", "Impostazioni"), showsChevron: true)
                ScreenTitle(title: tr("Reminders", "Promemoria"), large: false)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            Form {
                // ⚠️ Notifiche negate: spiego cosa fare
                if permission == .denied {
                    Section {
                        Label {
                            Text(tr("Notifications are off for DayMate. Turn them on in the iPhone Settings to get reminders.",
                                    "Le notifiche di DayMate sono spente. Accendile nelle Impostazioni dell'iPhone per ricevere i promemoria."))
                                .font(.subheadline)
                        } icon: {
                            Image(systemName: "bell.slash.fill")
                                .foregroundStyle(Theme.warning)
                        }
                        Button(tr("Open iPhone Settings", "Apri Impostazioni iPhone")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                    }
                    .listRowBackground(Theme.card)
                }

                // 📚 Studio
                Section {
                    Toggle(tr("Reminder to study", "Promemoria per studiare"), isOn: $studyOn)
                    if studyOn {
                        DatePicker(tr("Time", "Ora"), selection: studyTimeBinding,
                                   displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text(tr("Study", "Studio"))
                } footer: {
                    Text(tr("Every day it reminds you of your next tiny step.",
                            "Ogni giorno ti ricorda il tuo prossimo piccolo passo."))
                }
                .listRowBackground(Theme.card)

                // 🗓️ Impegni
                Section {
                    Toggle(tr("Alerts for your tasks", "Avvisi per gli impegni"), isOn: $tasksOn)
                    if tasksOn {
                        Picker(tr("How early", "Quanto prima"), selection: $leadMinutes) {
                            Text(tr("When it starts", "All'inizio")).tag(0)
                            ForEach([5, 10, 15, 30, 60], id: \.self) { Text("\($0) min").tag($0) }
                        }
                    }
                } header: {
                    Text("Planner")
                } footer: {
                    Text(tr("Only for tasks with a time, added in Plan.",
                            "Solo per gli impegni con un orario, aggiunti in Plan."))
                }
                .listRowBackground(Theme.card)

                // 🚩 Scadenze
                Section {
                    Toggle(tr("The day before, at 6 pm", "Il giorno prima, alle 18:00"), isOn: $deadlinesOn)
                } header: {
                    Text(tr("Deadlines and exams", "Scadenze ed esami"))
                } footer: {
                    Text(tr("For exams and for tasks marked \"It's a deadline\".",
                            "Per gli esami e per gli impegni segnati come \"È una scadenza\"."))
                }
                .listRowBackground(Theme.card)

                // 💧 Acqua
                Section {
                    Toggle(tr("Reminder to drink", "Promemoria per bere"), isOn: $waterOn)
                    if waterOn {
                        Picker(tr("Every", "Ogni"), selection: $waterEvery) {
                            Text(tr("1 hour", "1 ora")).tag(1)
                            Text(tr("2 hours", "2 ore")).tag(2)
                            Text(tr("3 hours", "3 ore")).tag(3)
                        }
                    }
                } header: {
                    Text(tr("Water", "Acqua"))
                } footer: {
                    Text(tr("From 10 am to 9 pm.", "Dalle 10 alle 21."))
                }
                .listRowBackground(Theme.card)

                // Prova
                Section {
                    Button {
                        ReminderManager.shared.sendTest()
                        Haptics.success()
                        withAnimation { testSent = true }
                    } label: {
                        Label(testSent ? tr("Arriving in 5 seconds…", "Arriva tra 5 secondi…")
                                       : tr("Send a test notification", "Manda una notifica di prova"),
                              systemImage: testSent ? "checkmark" : "bell.badge")
                    }
                } footer: {
                    Text(tr("Lock the phone to see it like a real one.",
                            "Blocca il telefono per vederla come una vera."))
                }
                .listRowBackground(Theme.card)
            }
            .scrollContentBackground(.hidden)
            .tint(Theme.main)
        }
        .dmScreen()
        // .task parte quando la schermata compare: controllo il permesso
        .task { await checkPermission() }
        // Quando cambia qualunque impostazione, rifaccio i promemoria
        .onChange(of: studyOn) { _, isOn in settingChanged(turnedOn: isOn) }
        .onChange(of: studyTime) { _, _ in settingChanged(turnedOn: false) }
        .onChange(of: tasksOn) { _, isOn in settingChanged(turnedOn: isOn) }
        .onChange(of: leadMinutes) { _, _ in settingChanged(turnedOn: false) }
        .onChange(of: deadlinesOn) { _, isOn in settingChanged(turnedOn: isOn) }
        .onChange(of: waterOn) { _, isOn in settingChanged(turnedOn: isOn) }
        .onChange(of: waterEvery) { _, _ in settingChanged(turnedOn: false) }
    }

    // MARK: - Azioni

    private func checkPermission() async {
        permission = await NotificationManager.shared.permissionStatus()
    }

    /// Rifà i promemoria. Se ho appena ACCESO qualcosa e il permesso non è mai stato
    /// chiesto, lo chiedo adesso (è il momento in cui l'utente capisce a cosa serve).
    private func settingChanged(turnedOn: Bool) {
        ReminderManager.shared.refresh(exams: exams, tasks: tasks)
        guard turnedOn else { return }
        Task {
            if await NotificationManager.shared.permissionStatus() == .notDetermined {
                _ = await NotificationManager.shared.askPermission()
            }
            await checkPermission()
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack { ReminderSettingsView() }
        .modelContainer(PreviewData.container)
}
