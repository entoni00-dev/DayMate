//
//  BreakView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Break time — 10 minutes, away from the screen" (schermata 06 di Sketch).
//
//  Il problema delle pause classiche: "solo un attimo" sul telefono diventa mezz'ora.
//  Qui la pausa ha:
//   1. un'attività concreta da scegliere ("PICK ONE"): sapere COSA fare riduce la tentazione
//   2. una durata precisa, con la sveglia "Welcome back!" alla fine
//   3. un ritorno facile: si riparte dal passo dove eri rimasto
//
//  Il timer parte SUBITO, anche mentre scegli l'attività:
//  la pausa è di X minuti, non "X minuti + il tempo per decidere".
//
//  💡 Il bottone onesto "In realtà ho preso il telefono 🙈": nessun rimprovero,
//  ma quella pausa non conta come "vera" nelle statistiche.
//

import SwiftUI

struct BreakView: View {
    let minutes: Int
    let isLong: Bool
    /// true = arrivo dalla fine di un blocco ("Nice work!"), false = pausa iniziale di "Stressed"
    let afterBlock: Bool
    /// es. "3 of 6 · Math"
    let progressText: String
    /// Timer della pausa finito → "Welcome back!"
    var onTimeUp: () -> Void
    /// L'utente riparte prima della fine. true = pausa fatta senza telefono
    var onBackEarly: (Bool) -> Void
    var onStop: () -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var suggestions = BreakActivity.defaults
    @State private var selected: BreakActivity?
    @State private var running: BreakActivity?
    @State private var countdown = Countdown()
    @State private var finished = false

    var body: some View {
        Group {
            // prima scelgo l'attività, poi vedo il timer della pausa
            if let running {
                runningView(running)
            } else {
                chooseView
            }
        }
        // .onAppear viene chiamato quando la schermata compare
        .onAppear {
            startTimer()
            // se il blocco è appena finito suona la "sveglia" della pausa
            if afterBlock {
                Haptics.alarm()
                SoundPlayer.shared.play(.pause)
            }
        }
        .onDisappear {
            countdown.stop()
            SoundPlayer.shared.stop()
            NotificationManager.shared.cancel(id: NotificationManager.breakID)
            LiveActivityManager.shared.end(isBreak: true)
        }
    }

    // MARK: - Scelta dell'attività

    private var chooseView: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenTitle(title: isLong ? tr("Long break", "Pausa lunga") : tr("Break time", "Pausa"),
                            subtitle: tr("\(minutes) minutes, away from the screen · \(countdown.remaining.mmss) left",
                                         "\(minutes) minuti, lontano dallo schermo · restano \(countdown.remaining.mmss)"))

                headerCard

                SectionHeader(text: tr("Pick one", "Scegline una"))

                VStack(spacing: 0) {
                    ForEach(suggestions) { activity in
                        Button {
                            Haptics.tap()
                            withAnimation(.snappy) { selected = activity }
                        } label: {
                            ActivityRowLabel(activity: activity, isChosen: selected == activity)
                        }
                        // quella scelta resta viola; le altre diventano viola al tocco
                        .buttonStyle(ChoiceButtonStyle(isSelected: selected == activity,
                                                       cornerRadius: 16, restColor: .clear))

                        if activity != suggestions.last {
                            RowDivider()
                        }
                    }
                }
                .cardBackground(radius: 18)

                Button {
                    Haptics.tap()
                    withAnimation {
                        suggestions = BreakActivity.suggestions()
                        selected = nil
                    }
                } label: {
                    Label(tr("Other ideas", "Altre idee"), systemImage: "shuffle")
                }
                .buttonStyle(QuietButtonStyle(color: Theme.lightMain))
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        // Il bottone principale resta sempre in fondo, anche scorrendo
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                Button(tr("Start my break", "Inizio la pausa")) {
                    Haptics.success()
                    SoundPlayer.shared.stop()
                    let chosen = selected ?? suggestions.first
                    withAnimation { running = chosen }
                    // 🏝️ sulla schermata di blocco compare l'attività scelta (es. "Short walk")
                    if let chosen {
                        LiveActivityManager.shared.changeStep(title: chosen.title,
                                                              subtitle: tr("Break time", "Pausa"))
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(tr("Skip the break", "Salta la pausa")) { endEarly(real: false) }
                    .buttonStyle(QuietButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .background(Theme.background)
        }
    }

    /// La card in alto: "STEP DONE · Nice work!" oppure "FIRST, BREATHE"
    private var headerCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(afterBlock ? tr("BLOCK DONE", "BLOCCO FATTO") : tr("FIRST, BREATHE", "PRIMA, RESPIRA"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accent)
                Text(afterBlock ? tr("Nice work!", "Ottimo lavoro!") : tr("Start with a break", "Si parte con una pausa"))
                    .font(.dmCardTitle)
                    .foregroundStyle(Theme.text)
                Text(afterBlock ? progressText
                                : tr("Then a short, easy step.", "Poi un passo corto e facile."))
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
            }
            Spacer()
            BlobView(pose: afterBlock ? .cheer : .pause)
                .frame(width: 64, height: 64)
        }
        .padding(20)
        .cardBackground(highlighted: true, radius: 22)
    }

    // MARK: - Pausa in corso

    private func runningView(_ activity: BreakActivity) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Label(activity.title, systemImage: activity.icon)
                    .font(.system(.subheadline, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                Text(tr("Phone down, enjoy it", "Telefono giù, goditela"))
                    .font(.dmTitle)
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
            }

            Spacer(minLength: 8)

            TimerRing(progress: countdown.progress, time: countdown.remaining.mmss)

            Text(tr("When it's time, the alarm rings.", "Quando è ora suona la sveglia."))
                .font(.subheadline)
                .foregroundStyle(Theme.secondary)

            Spacer(minLength: 8)

            Button(tr("Break done, back now", "Pausa fatta, riparto ora")) { endEarly(real: true) }
                .buttonStyle(PrimaryButtonStyle())
            Button(tr("Actually, I used my phone 🙈", "In realtà ho preso il telefono 🙈")) { endEarly(real: false) }
                .buttonStyle(QuietButtonStyle())
            Button(tr("Enough for today", "Per oggi basta così")) { onStop() }
                .buttonStyle(QuietButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Azioni

    private func startTimer() {
        guard !countdown.isRunning, !finished else { return }
        let seconds = TimeInterval(minutes * 60)
        countdown.onFinish = {
            guard !finished else { return }
            finished = true
            onTimeUp()
        }
        countdown.start(seconds: seconds)
        NotificationManager.shared.scheduleBackToStudy(after: seconds)
        // 🏝️ la pausa sulla schermata di blocco: così vedi quanto manca senza sbloccare
        LiveActivityManager.shared.start(examName: "",
                                         title: tr("Break time", "Pausa"),
                                         subtitle: "\(minutes) min",
                                         footer: tr("Away from the screen.", "Lontano dallo schermo."),
                                         isBreak: true,
                                         seconds: seconds)
    }

    private func endEarly(real: Bool) {
        guard !finished else { return }
        finished = true
        countdown.stop()
        NotificationManager.shared.cancel(id: NotificationManager.breakID)
        onBackEarly(real)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    BreakView(minutes: 10, isLong: false, afterBlock: true, progressText: "3 of 6 · Math",
              onTimeUp: {}, onBackEarly: { _ in }, onStop: {})
        .background(Theme.background)
}

/// Una riga di "Pick one": icona, attività, dettaglio, cerchio
private struct ActivityRowLabel: View {
    let activity: BreakActivity
    let isChosen: Bool
    // lo legge da ChoiceButtonStyle: true = sono viola
    @Environment(\.isLit) private var isLit

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemName: activity.icon, inverted: isLit)
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.dmRowTitle)
                    .foregroundStyle(isLit ? Theme.background : Theme.text)
                Text(activity.detail)
                    .font(.footnote)
                    .foregroundStyle(isLit ? Theme.background : Theme.secondary)
            }
            Spacer(minLength: 0)
            CheckCircle(state: isChosen ? .done : .todo)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
