//
//  StudyHomeView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  📚 "Study": si apre dalla Home quando tocchi "Study" (schermata 01 di Sketch).
//
//   ‹ Home
//   Study
//   Thursday 29 October
//   …TodayView: prossimo passo, "Add an exam", i tuoi esami…
//
//  "‹ Home" (o lo swipe da sinistra) riporta alla scelta Study / Plan my day.
//  La barra in basso resta visibile: Dubbi, Progressi e Impostazioni sono a un tocco.
//

import SwiftUI
import SwiftData

struct StudyHomeView: View {
    // @State = un valore che questa vista "ricorda": quando cambia, SwiftUI ridisegna la schermata
    @State private var showingAddExam = false

    var body: some View {
        VStack(spacing: 0) {
            // in Sketch il titolo è "Study" e al posto del "+" c'è il grande bottone "Add an exam"
            ModeHeader(showsHomeLink: true,
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
    NavigationStack { StudyHomeView() }
        .modelContainer(PreviewData.container)
}
