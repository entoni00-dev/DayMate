//
//  AddDoubtSheet.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  💭 Aggiungere un dubbio in qualsiasi momento (non solo durante un blocco di studio).
//  Scrivi la domanda, e se vuoi la colleghi a un esame e a un argomento:
//  così dopo, nei Dubbi, il Tutor AI sa di cosa si parla.
//

import SwiftUI
import SwiftData

struct AddDoubtSheet: View {
    // dismiss() chiude questa schermata (o il foglio) e torna indietro
    @Environment(\.dismiss) private var dismiss
    // modelContext = il "quaderno" di SwiftData: lo uso per inserire ed eliminare dati
    @Environment(\.modelContext) private var context
    // @Query legge i dati salvati con SwiftData e ridisegna la vista da sola quando cambiano
    @Query(sort: \Exam.date) private var exams: [Exam]

    /// Esame scelto in partenza (es. quando apri il foglio dal dettaglio di un esame)
    var preselectedExam: String? = nil

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var text = ""
    @State private var examName = ""
    @State private var topic = ""
    // @FocusState dice quale campo di testo ha la tastiera (così posso aprirla da codice)
    @FocusState private var textFocused: Bool

    private var upcoming: [Exam] { exams.filter { !$0.isPast } }

    private var selectedExam: Exam? {
        upcoming.first { $0.name == examName }
    }

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        // ScrollView: se il contenuto è più alto dello schermo, si scorre
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ScreenHeader(eyebrow: tr("Park it and keep going", "Parcheggialo e vai avanti"),
                             title: tr("New doubt", "Nuovo dubbio"))

                TextField(tr("E.g. Why does the limit of sin(x)/x equal 1?",
                             "Es. Perché il limite di sin(x)/x fa 1?"),
                          text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.body)
                    .focused($textFocused)
                    .padding(16)
                    .background(Theme.highlight, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                if !upcoming.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tr("Exam", "Esame"))
                            .font(.dmRowTitle)
                            .foregroundStyle(Theme.text)
                        chips(options: [""] + upcoming.map(\.name),
                              label: { $0.isEmpty ? tr("General", "Generale") : $0 },
                              selection: $examName)
                    }
                }

                if let selectedExam, !selectedExam.topics.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tr("Topic", "Argomento"))
                            .font(.dmRowTitle)
                            .foregroundStyle(Theme.text)
                        chips(options: [""] + selectedExam.topics,
                              label: { $0.isEmpty ? tr("Not sure", "Non so") : $0 },
                              selection: $topic)
                    }
                    .transition(.opacity)
                }

                Text(tr("You'll find it in Study → Doubts. With the AI tutor you can ask it there; otherwise take it to your professor or a classmate.",
                        "Lo ritrovi in Studio → Dubbi. Con il Tutor AI puoi chiederlo lì; altrimenti portalo al prof o a un compagno."))
                    .font(.caption)
                    .foregroundStyle(Theme.secondary)

                Button(tr("Save doubt", "Salva il dubbio"), action: save)
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSave)
            }
            .padding(24)
        }
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .animation(.snappy, value: examName)
        // .onAppear viene chiamato quando la schermata compare
        .onAppear {
            if let preselectedExam { examName = preselectedExam }
            textFocused = true
        }
        .onChange(of: examName) { _, _ in topic = "" }
    }

    /// Una fila di pillole scorrevole per scegliere un'opzione
    private func chips(options: [String], label: @escaping (String) -> String, selection: Binding<String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isOn = selection.wrappedValue == option
                    Button {
                        Haptics.tap()
                        selection.wrappedValue = option
                    } label: {
                        Text(label(option))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isOn ? .white : Theme.text)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isOn ? Theme.main : Theme.highlight, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    /// Creo il Doubt e lo inserisco nel database. Se non ho scelto un esame lo metto in "Generale".
    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        context.insert(Doubt(text: trimmed,
                             topic: topic,
                             examName: examName.isEmpty ? tr("General", "Generale") : examName))
        Haptics.success()
        dismiss()
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    AddDoubtSheet()
        .modelContainer(PreviewData.container)
}
