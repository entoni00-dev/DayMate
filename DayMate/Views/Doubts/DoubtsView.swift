//
//  DoubtsView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  I dubbi annotati durante i blocchi di studio.
//  Una lista ordinata da portare al prof o ai compagni.
//  Quando ne risolvi uno, puoi scrivere in due righe cosa hai capito:
//  diventa un appunto da ripassare (il "Cosa ho capito" sotto il dubbio).
//

import SwiftUI
import SwiftData
import TipKit

struct DoubtsView: View {
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \Doubt.createdAt, order: .reverse) private var doubts: [Doubt]
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context

    /// true = mostrata dentro lo spazio Studio
    var embedded = false
    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var showingAdd = false
    /// Il dubbio che sto segnando come risolto (per scrivere cosa ho capito)
    @State private var solving: Doubt?
    @State private var answerText = ""

    // Divido i dubbi in due liste: da risolvere e risolti
    // ($0 vuol dire "l'elemento che sto controllando", qui un Doubt)
    private var open: [Doubt] { doubts.filter { !$0.isResolved } }
    private var resolved: [Doubt] { doubts.filter { $0.isResolved } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !embedded {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        TopLink(title: tr("Back", "Indietro"), showsChevron: true)
                        Spacer()
                        Button {
                            showingAdd = true
                        } label: {
                            Label(tr("Doubt", "Dubbio"), systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.background)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Theme.main, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    ScreenHeader(eyebrow: tr("Parked", "Parcheggiati"), title: tr("Doubts", "Dubbi"))
                }
                .padding(.horizontal, 24)
            }

            List {
                // 💡 Suggerimento di TipKit
                TipView(DoubtTip())
                    .tint(Theme.lightMain)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))

                if doubts.isEmpty {
                    ContentUnavailableView(
                        tr("No doubts", "Nessun dubbio"),
                        systemImage: "bubble.left.and.exclamationmark.bubble.right",
                        description: Text(tr("Tap \"+ Doubt\" to write one down, or do it during a study block in 5 seconds without getting stuck.",
                                             "Tocca \"+ Dubbio\" per scriverne uno, oppure fallo durante un blocco di studio: 5 secondi e vai avanti senza bloccarti."))
                    )
                    .listRowBackground(Color.clear)
                }

                if !open.isEmpty {
                    Section(tr("To solve", "Da risolvere")) {
                        ForEach(open) { doubt in
                            row(doubt)
                        }
                        .onDelete { offsets in delete(offsets, from: open) }
                    }
                    .listRowBackground(Theme.card)
                }

                if !resolved.isEmpty {
                    Section(tr("Solved", "Risolti")) {
                        ForEach(resolved) { doubt in
                            row(doubt)
                        }
                        .onDelete { offsets in delete(offsets, from: resolved) }
                    }
                    .listRowBackground(Theme.card)
                }

                if !open.isEmpty {
                    Section {
                        Text(tr("Take this list to your professor's office hours or ask a classmate. A written doubt is already half solved.",
                                "Porta questa lista al ricevimento del prof o chiedi a un compagno. Un dubbio scritto è già mezzo risolto."))
                            .font(.footnote)
                            .foregroundStyle(Theme.secondary)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .dmScreen(standalone: !embedded)
        // .sheet = un foglio che sale dal basso sopra la schermata
        .sheet(isPresented: $showingAdd) {
            AddDoubtSheet()
        }
        // Quando segno un dubbio come risolto, chiedo (facoltativo) cosa ho capito
        .alert(tr("What did you understand?", "Cosa hai capito?"),
               isPresented: Binding(get: { solving != nil }, set: { if !$0 { solving = nil } })) {
            TextField(tr("Two lines are enough", "Bastano due righe"), text: $answerText)
            Button(tr("Save", "Salva")) { markSolved(withAnswer: true) }
            Button(tr("Skip", "Salta"), role: .cancel) { markSolved(withAnswer: false) }
        } message: {
            Text(tr("It becomes a note to review before the exam.",
                    "Diventa un appunto da ripassare prima dell'esame."))
        }
    }

    /// Segna il dubbio come risolto, con o senza l'appunto
    private func markSolved(withAnswer: Bool) {
        guard let doubt = solving else { return }
        let text = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        if withAnswer && !text.isEmpty { doubt.answer = text }
        // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
        withAnimation { doubt.isResolved = true }
        Haptics.success()
        answerText = ""
        solving = nil
    }

    private func row(_ doubt: Doubt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(doubt.text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.text)
                .strikethrough(doubt.isResolved)

            Text([doubt.examName, doubt.topic, doubt.createdAt.formatted(.relative(presentation: .named).locale(L10n.locale))]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Theme.secondary)

            if let answer = doubt.answer {
                // 💡 l'appunto scritto quando l'ho risolto
                Label(tr("What I understood", "Cosa ho capito"), systemImage: "lightbulb.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
                Text(answer)
                    .font(.subheadline)
                    .foregroundStyle(Theme.text)
                    .lineLimit(6)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.highlight, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 10) {
                Spacer()

                Button {
                    if doubt.isResolved {
                        // riapro il dubbio (l'appunto resta, non si perde niente)
                        withAnimation { doubt.isResolved = false }
                    } else {
                        // prima chiedo cosa ho capito (vedi .alert sopra)
                        answerText = doubt.answer ?? ""
                        solving = doubt
                    }
                } label: {
                    Label(doubt.isResolved ? tr("Reopen", "Riapri") : tr("Solved", "Risolto"),
                          systemImage: doubt.isResolved ? "arrow.uturn.backward" : "checkmark.circle")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderless)
                .tint(Theme.accent)
            }
        }
        .padding(.vertical, 4)
    }

    /// Chiamata dallo swipe "Elimina" della lista: offsets sono le posizioni delle righe da togliere
    private func delete(_ offsets: IndexSet, from list: [Doubt]) {
        for index in offsets {
            context.delete(list[index])
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack { DoubtsView() }
        .modelContainer(PreviewData.container)
}
