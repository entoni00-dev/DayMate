//
//  SessionFlowView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il contenitore della sessione di studio: mostra la schermata giusta
//  in base alla fase di StudySessionModel.
//
//   Mood ─► [riscaldamento → scelta] ─► Timer ─► "Time for a break!" ─► Break ─► "Welcome back!" ─┐
//                                         ▲                                                         │
//                                         └─────────────────────────────────────────────────────────┘
//   In ogni momento: "Stop for today" ─► umore di fine ─► riepilogo
//
//  🧠 Architettura (MVVM):
//   - StudySessionModel = il "cervello" (stato + decisioni)
//   - SessionFlowView   = il "regista" (quale schermata mostrare + il bottoncino in alto)
//   - le sottoviste     = mostrano dati e comunicano le scelte con delle closure
//

import SwiftUI
import SwiftData

struct SessionFlowView: View {
    // dismiss() chiude questa schermata (o il foglio) e torna indietro
    @Environment(\.dismiss) private var dismiss
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    /// Il ViewModel. Uso @State con una classe @Observable (iOS 17): SwiftUI la crea
    /// una volta sola e ridisegna le viste quando cambiano le proprietà lette.
    @State private var model: StudySessionModel

    init(exam: Exam) {
        _model = State(initialValue: StudySessionModel(exam: exam))
    }

    /// Le schermate "sveglia" coprono tutto: lì niente bottoncino in alto
    private var isAlertPhase: Bool {
        model.phase == .pauseAlert || model.phase == .studyAlert
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isAlertPhase && model.phase != .summary {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .zIndex(1)
            }

            phaseView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // .id: ogni fase è una vista nuova → parte la transizione
                .id(model.phase)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
        .background(Theme.paper.ignoresSafeArea())
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: model.phase)
        .environment(\.locale, L10n.locale)
        // Si chiude solo coi bottoni (evito chiusure accidentali)
        .interactiveDismissDisabled()
        // Lo schermo NON resta acceso: vogliamo proprio che il telefono venga messo giù
    }

    // MARK: - Il bottoncino "‹ …" in alto, come in Sketch

    @ViewBuilder
    private var topBar: some View {
        HStack {
            switch model.phase {
            case .checkIn:
                BackPill(title: tr("Exams", "Esami"), action: close)
            case .warmUpPreview:
                BackPill(title: tr("Mood", "Umore"), action: { model.backToCheckIn() })
            case .ready:
                if model.canGoBackToMood {
                    BackPill(title: tr("Mood", "Umore"), action: { model.backToCheckIn() })
                } else {
                    BackPill(title: tr("Close", "Chiudi"), systemImage: "xmark", action: close)
                }
            case .breakTime:
                // "‹ Timer": salto la pausa e torno a studiare
                BackPill(title: "Timer", action: { model.backFromBreak(real: false) })
            default:
                BackPill(title: tr("Close", "Chiudi"), systemImage: "xmark", action: close)
            }
            Spacer()
            Text(model.exam.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.mute)
                .lineLimit(1)
        }
    }

    private func close() {
        model.closeEarly()
        dismiss()
    }

    // MARK: - Schermata della fase corrente

    @ViewBuilder
    private var phaseView: some View {
        switch model.phase {

        case .checkIn:
            CheckInView(eyebrow: tr("Before studying…", "Prima di studiare…"),
                        title: tr("How do you feel?", "Come ti senti?")) { mood in
                model.checkIn(mood, context: context)
            }

        case .warmUpPreview:
            if let warm = model.warmUp {
                StepPreviewView(step: warm, mood: model.mood,
                                onStart: { model.startWarmUp() },
                                onShrink: { model.shrinkWarmUp() })
            }

        case .warmUp:
            if let warm = model.warmUp {
                FocusTimerView(step: warm) { elapsed, _ in
                    model.warmUpFinished(elapsedSeconds: elapsed)
                }
            }

        case .choice:
            ChoiceView(elapsedSeconds: model.lastWarmUpSeconds,
                       nextBlockMinutes: model.nextBlockMinutes,
                       onContinue: { model.continueStudying() },
                       onBreak: { model.takeBreak() },
                       onStop: { model.stop() })

        case .ready:
            BlockReadyView(model: model,
                           onStart: { model.startBlock() },
                           onBreak: { model.takeBreak() })

        case .block:
            FocusBlockView(model: model)

        case .pauseAlert:
            PhaseAlertView(
                kind: .pause,
                message: tr("You studied for \(model.lastBlockMinutes) minutes. Now \(model.breakMinutes) minutes away from the screen.",
                            "Hai studiato \(model.lastBlockMinutes) minuti. Ora \(model.breakMinutes) minuti lontano dallo schermo."),
                actions: [
                    .init(title: tr("Have a break (\(model.breakMinutes) min)", "Vado in pausa (\(model.breakMinutes) min)"),
                          style: .honey, action: { model.takeBreak() }),
                    .init(title: tr("Skip the break, I'm focused", "Salto la pausa, sono concentrato"),
                          style: .link, action: { model.skipBreak() }),
                    .init(title: tr("Enough for today", "Per oggi basta così"),
                          style: .link, action: { model.stop() }),
                ]
            )

        case .breakTime:
            BreakView(minutes: model.breakMinutes,
                      isLong: model.isLongBreak,
                      onTimeUp: { model.breakTimeUp() },
                      onBackEarly: { real in model.backFromBreak(real: real) },
                      onStop: { model.stop() })

        case .studyAlert:
            PhaseAlertView(
                kind: .study,
                message: studyAlertMessage,
                actions: [
                    .init(title: tr("Back to study!", "Si torna a studiare!"),
                          style: .dark, action: { model.backFromBreak(real: true) }),
                    // "Home" di Sketch: finisco qui → umore di fine → riepilogo → chiudo
                    .init(title: "Home", style: .honey, action: { model.stop() }),
                    .init(title: tr("Back, but I used my phone 🙈", "Riparto, ma ho usato il telefono 🙈"),
                          style: .link, action: { model.backFromBreak(real: false) }),
                ]
            )

        case .checkOut:
            CheckInView(eyebrow: model.allDone ? tr("All steps done!", "Hai finito tutti i passi!")
                                               : tr("After studying…", "Dopo lo studio…"),
                        title: tr("And now, how do you feel?", "E adesso come ti senti?"),
                        bubbleText: { _ in
                            tr("Compare it with the start: it's just for you, to notice how anxiety changes.",
                               "Confrontalo con l'inizio: serve solo a te, per notare come cambia l'ansia.")
                        },
                        buttonTitle: tr("Done", "Fatto")) { mood in
                model.finishCheckOut(mood)
            }

        case .summary:
            if let session = model.session {
                SessionSummaryView(session: session, allDone: model.allDone) {
                    dismiss()
                }
            }
        }
    }

    /// Nel "Welcome back!" ricordo da dove si riparte: niente "e ora che faccio?"
    private var studyAlertMessage: String {
        if let step = model.currentStep {
            return tr("Next up: \(step.title)", "Si riparte da: \(step.title)")
        }
        return tr("One tiny step at a time.", "Un passo alla volta.")
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    SessionFlowView(exam: PreviewData.sampleExam)
        .modelContainer(PreviewData.container)
}
