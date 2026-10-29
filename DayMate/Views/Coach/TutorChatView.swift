//
//  TutorChatView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La chat con il Tutor AI (solo iOS 26+ con Apple Intelligence).
//  Tutto il file è dentro #if: su Xcode senza il framework semplicemente non esiste.
//

#if canImport(FoundationModels)

import SwiftUI

@available(iOS 26.0, *)
struct TutorChatView: View {
    /// Argomenti degli esami, per le azioni rapide
    let topics: [String]
    /// Domanda da inviare subito (es. un dubbio parcheggiato)
    var initialPrompt: String?
    /// Chiamata con la prima risposta (per salvarla nel dubbio)
    var onAnswer: ((String) -> Void)?

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var chat = TutorChat()
    @State private var input = ""
    @State private var selectedTopic = ""
    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                BackPill(title: "Coach")
                Spacer()
                Button {
                    chat.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundStyle(Theme.rust)
                        .frame(width: 44, height: 44)
                        .background(Theme.pillGray, in: Circle())
                }
                .disabled(chat.messages.isEmpty)
                .accessibilityLabel(tr("New conversation", "Nuova conversazione"))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            ScrollViewReader { proxy in
                // ScrollView: se il contenuto è più alto dello schermo, si scorre
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        disclaimer

                        ForEach(chat.messages) { message in
                            bubble(message)
                                .id(message.id)
                        }

                        if chat.isThinking {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text(tr("Thinking…", "Sto pensando…"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 4)
                        }
                    }
                    .padding()
                }
                .onChange(of: chat.messages.count) { _, _ in
                    if let last = chat.messages.last {
                        // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            if !topics.isEmpty {
                quickActions
            }

            inputBar
        }
        .dmScreen()
        .task {
            if selectedTopic.isEmpty { selectedTopic = topics.first ?? "" }
            if let initialPrompt, chat.messages.isEmpty {
                if let answer = await chat.send(initialPrompt) {
                    onAnswer?(answer)
                }
            }
        }
    }

    // MARK: - Pezzi della UI

    private var disclaimer: some View {
        Label {
            Text(tr("It runs on your iPhone: nothing leaves your phone. It's a small model and can be wrong: always check your book.",
                    "Gira sul tuo iPhone: niente esce dal telefono. È un modello piccolo e può sbagliare: controlla sempre sul libro."))
                .font(.caption)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(Theme.leaf)
        }
        .padding(12)
        .background(Theme.cream, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func bubble(_ message: TutorChat.Message) -> some View {
        HStack {
            if message.fromUser { Spacer(minLength: 40) }
            Text(markdown(message.text))
                .font(.body)
                .foregroundStyle(message.fromUser ? Color.white : Theme.ink)
                .padding(12)
                .background(message.fromUser ? Theme.cocoa : Color.white,
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .textSelection(.enabled)
            if !message.fromUser { Spacer(minLength: 40) }
        }
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Scelta dell'argomento
                Menu {
                    ForEach(topics, id: \.self) { topic in
                        Button(topic) { selectedTopic = topic }
                    }
                } label: {
                    Label(selectedTopic.isEmpty ? tr("Topic", "Argomento") : selectedTopic, systemImage: "book.closed")
                        .font(.caption.bold())
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.honeySoft, in: Capsule())
                }

                ForEach(AITutor.QuickAction.allCases) { action in
                    Button(action.label) {
                        guard !selectedTopic.isEmpty else { return }
                        Task { await chat.send(action.prompt(for: selectedTopic)) }
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.lilacSoft, in: Capsule())
                    .disabled(chat.isThinking)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(tr("Ask the tutor something…", "Chiedi qualcosa al tutor…"), text: $input, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                let text = input
                input = ""
                Task { await chat.send(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.cocoa)
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || chat.isThinking)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    /// Il modello risponde spesso con **grassetti** e liste: li rendo come Markdown
    private func markdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

#endif
