//
//  DoubtsView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  I dubbi annotati durante i blocchi di studio.
//  Con il Tutor AI disponibile: "Ask the tutor" e la risposta viene salvata.
//  Senza AI: restano una lista ordinata da portare al prof o ai compagni.
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

    // Divido i dubbi in due liste: da risolvere e risolti
    // ($0 vuol dire "l'elemento che sto controllando", qui un Doubt)
    private var open: [Doubt] { doubts.filter { !$0.isResolved } }
    private var resolved: [Doubt] { doubts.filter { $0.isResolved } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !embedded {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        BackPill(title: "Coach")
                        Spacer()
                        Button {
                            showingAdd = true
                        } label: {
                            Label(tr("Doubt", "Dubbio"), systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Theme.cocoa, in: Capsule())
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
                    .tint(Theme.rust)
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
                }

                if !resolved.isEmpty {
                    Section(tr("Solved", "Risolti")) {
                        ForEach(resolved) { doubt in
                            row(doubt)
                        }
                        .onDelete { offsets in delete(offsets, from: resolved) }
                    }
                }

                if !AITutor.isAvailable && !open.isEmpty {
                    Section {
                        Text(tr("Without the AI tutor: take this list to your professor's office hours or ask a classmate. A written doubt is already half solved.",
                                "Senza Tutor AI: porta questa lista al ricevimento del prof o chiedi a un compagno. Un dubbio scritto è già mezzo risolto."))
                            .font(.footnote)
                            .foregroundStyle(Theme.mute)
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
    }

    private func row(_ doubt: Doubt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(doubt.text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .strikethrough(doubt.isResolved)

            Text([doubt.examName, doubt.topic, doubt.createdAt.formatted(.relative(presentation: .named).locale(L10n.locale))]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Theme.mute)

            if let answer = doubt.answer {
                Text(answer)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(6)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.lilacSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            HStack(spacing: 10) {
                if let chat = AITutor.chatView(
                    topics: [doubt.topic],
                    initialPrompt: AITutor.doubtPrompt(doubt),
                    onAnswer: { answer in doubt.answer = answer }
                ) {
                    NavigationLink {
                        chat
                    } label: {
                        Label(tr("Ask the tutor", "Chiedi al tutor"), systemImage: "sparkles")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.borderless)
                    .tint(Theme.rust)
                }

                Spacer()

                Button {
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation { doubt.isResolved.toggle() }
                } label: {
                    Label(doubt.isResolved ? tr("Reopen", "Riapri") : tr("Solved", "Risolto"),
                          systemImage: doubt.isResolved ? "arrow.uturn.backward" : "checkmark.circle")
                        .font(.caption.bold())
                }
                .buttonStyle(.borderless)
                .tint(Theme.leaf)
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
