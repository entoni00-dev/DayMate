//
//  SessionFlowView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il contenitore della sessione di studio: mostra la schermata giusta
//  in base alla fase di StudySessionModel.
//
//   Mood ─► Timer ─► Break ("Nice work!") ─► Welcome back ─► Timer ─► …
//   In ogni momento: "basta per oggi" ─► umore di fine ─► riepilogo
//
//  🧠 Architettura (MVVM):
//   - StudySessionModel = il "cervello" (stato + decisioni)
//   - SessionFlowView   = il "regista" (quale schermata mostrare + il link "Cancel" in alto)
//   - le sottoviste     = mostrano dati e comunicano le scelte con delle closure
//

import SwiftUI
import SwiftData

struct SessionFlowView: View {
    // dismiss() chiude la sessione (è una fullScreenCover)
    @Environment(\.dismiss) private var dismiss
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    /// Il ViewModel. Uso @State con una classe @Observable (iOS 17): SwiftUI la crea
    /// una volta sola e ridisegna le viste quando cambiano le proprietà lette.
    @State private var model: StudySessionModel

    init(exam: Exam) {
        _model = State(initialValue: StudySessionModel(exam: exam))
    }

    /// In queste fasi in alto c'è il link "Cancel / Chiudi"
    private var showsTopLink: Bool {
        model.phase != .studyAlert && model.phase != .summary && model.phase != .checkOut
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsTopLink {
                HStack {
                    TopLink(title: model.phase == .checkIn ? tr("Cancel", "Annulla") : tr("Close", "Chiudi"),
                            action: close)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
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
        .background(Theme.background.ignoresSafeArea())
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: model.phase)
        // Si chiude solo coi bottoni (evito chiusure accidentali col trascinamento)
        .interactiveDismissDisabled()
        // Lo schermo NON resta acceso: vogliamo proprio che il telefono venga messo giù
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
            CheckInView(title: tr("How do you feel?", "Come ti senti?"),
                        subtitle: tr("Your next step adapts to you", "Il prossimo passo si adatta a te")) { mood in
                model.checkIn(mood, context: context)
            }

        case .warmUp:
            if let warm = model.warmUp {
                FocusTimerView(step: warm,
                               onFinish: { elapsed, _ in model.warmUpFinished(elapsedSeconds: elapsed) },
                               onAnotherStep: { model.anotherWarmUp() })
            }

        case .choice:
            ChoiceView(elapsedSeconds: model.lastWarmUpSeconds,
                       nextBlockMinutes: model.nextBlockMinutes,
                       onContinue: { model.continueStudying() },
                       onBreak: { model.takeBreak() },
                       onStop: { model.stop() })

        case .block:
            FocusBlockView(model: model)

        case .breakTime:
            BreakView(minutes: model.breakMinutes,
                      isLong: model.isLongBreak,
                      afterBlock: model.breakAfterBlock,
                      progressText: tr("\(model.exam.doneCount) of \(model.exam.steps.count) · \(model.exam.name)",
                                       "\(model.exam.doneCount) di \(model.exam.steps.count) · \(model.exam.name)"),
                      onTimeUp: { model.breakTimeUp() },
                      onBackEarly: { real in model.backFromBreak(real: real) },
                      onStop: { model.stop() })

        case .studyAlert:
            WelcomeBackView(exam: model.exam,
                            step: model.currentStep,
                            stepNumber: model.stepNumber,
                            minutes: model.nextBlockMinutes,
                            onStart: { model.backFromBreak(real: true) },
                            onNotNow: { model.stop() },
                            onUsedPhone: { model.backFromBreak(real: false) })

        case .checkOut:
            CheckInView(title: model.allDone ? tr("All steps done! How do you feel?", "Tutti i passi fatti! Come ti senti?")
                                             : tr("And now, how do you feel?", "E adesso come ti senti?"),
                        subtitle: tr("Compare it with the start: it's just for you.",
                                     "Confrontalo con l'inizio: serve solo a te."),
                        isCheckOut: true) { mood in
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
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    SessionFlowView(exam: PreviewData.sampleExam)
        .modelContainer(PreviewData.container)
}
