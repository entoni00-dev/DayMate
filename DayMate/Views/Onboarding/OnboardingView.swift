//
//  OnboardingView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La prima volta che apri l'app:
//   1. "First Page" di Sketch: il bradipo appeso al ramo + il bottone "Slooow" da far scorrere
//   2. tre schermate che spiegano l'idea in 20 secondi
//   3. "Come vuoi usare DayMate?" → Studio oppure Planner (i due modi dell'app)
//
//  Dalla seconda apertura in poi si parte direttamente dalla Home:
//  ogni tocco in più tra "apro l'app" e "inizio a studiare" è un'occasione per mollare.
//

import SwiftUI

/// Dati di una pagina dell'introduzione
private struct IntroPage {
    let pose: SlothPose
    let eyebrow: String
    let title: String
    let text: String
}

struct OnboardingView: View {
    /// Se true salto le presentazioni e mostro solo la scelta della modalità
    var onlyModeChoice = false
    /// Chiamata alla fine, con la modalità scelta
    var onFinish: (AppMode) -> Void

    private enum Stage { case welcome, intro, choice }
    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var stage: Stage = .welcome
    @State private var page = 0

    private let pages: [IntroPage] = [
        IntroPage(pose: .stuck,
                  eyebrow: tr("The problem", "Il problema"),
                  title: tr("Starting is the hard part", "Il difficile è iniziare"),
                  text: tr("When an exam looks huge, anxiety rises and the easiest escape is scrolling. Scrolling isn't the problem: it's the symptom.",
                           "Quando un esame sembra enorme, sale l'ansia e la fuga più facile è scrollare. Lo scrolling non è il problema: è il sintomo.")),
        IntroPage(pose: .reading,
                  eyebrow: tr("The idea", "L'idea"),
                  title: tr("Tiny steps, real times", "Passi piccoli, tempi veri"),
                  text: tr("Tell DayMate how many pages each topic has: it builds a day-by-day plan of 10-15 minute steps. And if you're stuck, you start with something tiny: \"open the book\".",
                           "Dici a DayMate quante pagine ha ogni argomento: crea un piano giorno per giorno con passi da 10-15 minuti. E se sei bloccato, si parte da un gesto minuscolo: \"apri il libro\".")),
        IntroPage(pose: .hat,
                  eyebrow: tr("The rhythm", "Il ritmo"),
                  title: tr("Study, then a real break", "Studio, poi una pausa vera"),
                  text: tr("Study blocks and breaks take turns on their own, with an alarm. And everything stays on your iPhone: no account, no server, no social.",
                           "Blocchi di studio e pause si alternano da soli, con una sveglia. E tutto resta sul tuo iPhone: niente account, niente server, niente social.")),
    ]

    var body: some View {
        ZStack {
            switch onlyModeChoice ? .choice : stage {
            case .welcome:
                welcome
                    .transition(.opacity)
            case .intro:
                introPages
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .choice:
                ModeChoiceView(onChoose: onFinish)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: stage)
    }

    // MARK: - First Page

    private var welcome: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                LanguageToggle()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            SlothView(pose: .hanging)
                .frame(maxWidth: .infinity, maxHeight: 440)
                .padding(.top, 4)

            Spacer(minLength: 12)

            VStack(spacing: 6) {
                Text("DayMate")
                    .font(.dmHuge)
                    .foregroundStyle(Theme.ink)
                Text(tr("One tiny step at a time", "Un piccolo passo alla volta"))
                    .font(.dmSerif)
                    .foregroundStyle(Theme.mute)
            }

            Spacer(minLength: 12)

            SlideToStart(title: "Slooow") {
                stage = .intro
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Le 3 pagine

    private var introPages: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(tr("Skip", "Salta"), action: finish)
                    .buttonStyle(TextLinkStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Pallini
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.cocoa : Theme.stone)
                        .frame(width: index == page ? 22 : 8, height: 8)
                }
            }
            .animation(.snappy, value: page)
            .padding(.bottom, 20)

            Button {
                if page == pages.count - 1 {
                    finish()
                } else {
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation { page += 1 }
                }
            } label: {
                Text(page == pages.count - 1 ? tr("Continue", "Continua") : tr("Next", "Avanti"))
            }
            .buttonStyle(PillButtonStyle(variant: page == pages.count - 1 ? .honey : .dark))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background {
            ZStack {
                Theme.paper
                DecoCircles()
            }
            .ignoresSafeArea()
        }
    }

    private func pageView(_ data: IntroPage) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 0)
            SlothView(pose: data.pose)
                .frame(maxWidth: .infinity, maxHeight: 260)
            ScreenHeader(eyebrow: data.eyebrow, title: data.title)
            Text(data.text)
                .font(.body)
                .foregroundStyle(Theme.mute)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 28)
    }

    private func finish() {
        // Chiedo il permesso per le notifiche qui, dopo aver spiegato PERCHÉ servono
        // (la sveglia di fine blocco): così è più probabile che l'utente dica sì.
        NotificationManager.shared.requestPermission()
        stage = .choice
    }
}

// MARK: - Il bottone "Slooow" da far scorrere

/// Capsula scura con l'avatar del bradipo: trascinalo verso destra (o tocca) per entrare.
struct SlideToStart: View {
    let title: String
    var onComplete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var done = false

    var body: some View {
        // GeometryReader mi dice quanto spazio ho a disposizione (larghezza/altezza)
        GeometryReader { geometry in
            let knob: CGFloat = 54
            let maxOffset = max(geometry.size.width - knob - 12, 1)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.cocoa)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 4)

                HStack {
                    Text(title)
                        .font(.system(.title, weight: .medium))
                        .foregroundStyle(Theme.honey)
                        .opacity(1 - Double(offset / maxOffset))
                        .padding(.leading, knob + 26)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.lilac)
                        .padding(.trailing, 22)
                }

                SlothView(pose: .head)
                    .padding(6)
                    .frame(width: knob, height: knob)
                    .background(Theme.cream, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.honey, lineWidth: 3))
                    .offset(x: 6 + offset)
                    .gesture(
                        // DragGesture = il dito che trascina
                        DragGesture()
                            .onChanged { value in
                                guard !done else { return }
                                offset = min(max(0, value.translation.width), maxOffset)
                            }
                            .onEnded { _ in
                                if offset > maxOffset * 0.6 {
                                    complete(maxOffset: maxOffset)
                                } else {
                                    withAnimation(.spring()) { offset = 0 }
                                }
                            }
                    )
            }
            .contentShape(Capsule())
            // Anche un semplice tocco funziona: non tutti capiscono che va trascinato
            .onTapGesture { complete(maxOffset: maxOffset) }
        }
        .frame(height: 68)
        .accessibilityElement()
        .accessibilityLabel(tr("Start DayMate", "Inizia DayMate"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onComplete() }
    }

    private func complete(maxOffset: CGFloat) {
        guard !done else { return }
        done = true
        Haptics.success()
        withAnimation(.spring(response: 0.35)) { offset = maxOffset }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onComplete() }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    OnboardingView { _ in }
}
