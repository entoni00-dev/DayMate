//
//  StudyHomeView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  📚 "Study" (schermata 01 di Sketch): la prima sezione della modalità Studio.
//
//   ‹ Home
//   Study
//   Thursday 29 October
//   …TodayView: prossimo passo, "Add an exam", i tuoi esami, il piano di oggi…
//
//  "‹ Home" porta alla prima sezione della barra, dove si sceglie Study o Plan my day.
//

import SwiftUI
import SwiftData

struct StudyHomeView: View {
    /// Cosa fare quando tocco "‹ Home" (la decide RootView: apre la sezione Home)
    var onHome: () -> Void

    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var showingAddExam = false

    var body: some View {
        VStack(spacing: 0) {
            // in Sketch il titolo è "Study" e al posto del "+" c'è il grande bottone "Add an exam"
            ModeHeader(onHome: onHome,
                       title: tr("Study", "Studio"),
                       subtitle: Date.now.longDayText)

            TodayView(onAddExam: { showingAddExam = true })
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .dmScreen()
        .dmTabBar()
        // "Add an exam" apre la schermata "New exam" (schermata 03)
        .navigationDestination(isPresented: $showingAddExam) {
            AddExamView()
                // mentre scrivo un nuovo esame la barra in basso sparisce: meno distrazioni
                .toolbar(.hidden, for: .tabBar)
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    NavigationStack { StudyHomeView(onHome: {}) }
        .modelContainer(PreviewData.container)
}
