//
//  BreakView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  "Take a real break" di Sketch: l'app propone attività reali al posto dello scrolling.
//
//  Il problema delle pause classiche: "solo un attimo" sul telefono diventa mezz'ora.
//  Qui la pausa ha:
//   1. un'attività concreta (sapere COSA fare riduce la tentazione del telefono)
//   2. una durata precisa, con la sveglia "Welcome back!" alla fine
//   3. un ritorno facile: si riparte dal passo dove eri rimasto
//
//  Il timer parte SUBITO, anche mentre scegli l'attività:
//  la pausa è di X minuti, non "X minuti + il tempo per decidere".
//
//  💡 Il bottone onesto "Actually I used my phone 🙈": nessun rimprovero,
//  ma quella pausa non conta come "vera" nelle statistiche.
//

import SwiftUI

struct BreakView: View {
    let minutes: Int
    let isLong: Bool
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
            if let running {
                runningView(running)
            } else {
                chooseView
            }
        }
        // .onAppear viene chiamato quando la schermata compare
        .onAppear(perform: startTimer)
        .onDisappear {
            countdown.stop()
            NotificationManager.shared.cancel(id: NotificationManager.breakID)
        }
    }

    // MARK: - Scelta dell'attività

    private var chooseView: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    ScreenHeader(eyebrow: tr("\(minutes) minutes", "\(minutes) minuti"),
                                 title: isLong ? tr("Take a long break", "Fai una pausa lunga")
                                               : tr("Take a real break", "Fai una pausa vera"),
                                 subtitle: isLong
                                    ? tr("4 blocks done: you deserve a real rest. Go out, move, eat something.",
                                         "4 blocchi fatti: ti meriti uno stacco vero. Esci, muoviti, mangia qualcosa.")
                                    : tr("Pick something to do away from the screen.",
                                         "Scegli una cosa da fare lontano dallo schermo."))
                    Image(systemName: "sun.max")
                        .font(.system(size: 54, weight: .light))
                        .foregroundStyle(Theme.honey)
                        .accessibilityHidden(true)
                }

                Label(tr("\(countdown.remaining.mmss) left", "restano \(countdown.remaining.mmss)"), systemImage: "timer")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.mute)
                    .padding(.bottom, 16)

                ForEach(suggestions) { activity in
                    Button {
                        Haptics.tap()
                        // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                        withAnimation(.snappy) { selected = activity }
                    } label: {
                        HStack(spacing: 8) {
                            Text(activity.emoji)
                            Text(activity.title)
                            if selected == activity {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                    }
                    .buttonStyle(PillButtonStyle(variant: .honey, height: 60))
                    .overlay(Capsule().strokeBorder(selected == activity ? Theme.cocoa : .clear, lineWidth: 3))
                }

                Button {
                    Haptics.tap()
                    withAnimation {
                        suggestions = BreakActivity.suggestions()
                        selected = nil
                    }
                } label: {
                    Label(tr("Other ideas", "Altre idee"), systemImage: "shuffle")
                }
                .buttonStyle(TextLinkStyle(color: Theme.rust))
                .frame(maxWidth: .infinity)

                HStack(alignment: .bottom) {
                    Button(tr("Skip the break", "Salta la pausa")) { endEarly(real: false) }
                        .buttonStyle(TextLinkStyle())
                    Spacer()
                    SlothView(pose: .hat)
                        .frame(width: 100, height: 110)
                }
                .padding(.top, 8)

                Button(tr("Start my break", "Inizio la pausa")) {
                    Haptics.success()
                    withAnimation { running = selected ?? suggestions.first }
                }
                .buttonStyle(PillButtonStyle(variant: .dark))
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Pausa in corso

    private func runningView(_ activity: BreakActivity) -> some View {
        TimerScreen(
            eyebrow: "\(activity.emoji) \(activity.title)",
            title: tr("Phone down, enjoy it", "Telefono giù, goditela"),
            subtitle: activity.detail,
            progress: countdown.progress,
            active: true,
            pose: .hat,
            time: countdown.remaining.mmss,
            caption: tr("When it's time, the alarm rings: Welcome back!",
                        "Quando è ora suona la sveglia: Bentornato!")
        ) {
            EmptyView()
        } buttons: {
            Button(tr("Break done, back now", "Pausa fatta, riparto ora")) { endEarly(real: true) }
                .buttonStyle(PillButtonStyle(variant: .dark))
            Button(tr("Actually, I used my phone 🙈", "In realtà ho preso il telefono 🙈")) { endEarly(real: false) }
                .buttonStyle(TextLinkStyle())
            Button(tr("Enough for today", "Per oggi basta così")) { onStop() }
                .buttonStyle(TextLinkStyle())
        }
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
    BreakView(minutes: 5, isLong: false, onTimeUp: {}, onBackEarly: { _ in }, onStop: {})
}
