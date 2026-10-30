//
//  RootView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La vista "radice": decide cosa mostrare.
//
//  🧭 Come si entra nell'app (OGNI volta che la apri):
//
//              schermata iniziale "DayMate — One tiny step at a time"
//                          │
//              ┌───────────┴──────────────┐
//              ▼                          ▼
//   📚 MODALITÀ STUDIO              🗓️ MODALITÀ PLANNER
//   barra in basso:                  barra in basso:
//   Oggi · Dubbi · Progressi · ⚙️    Giorno · Settimana · Scadenze · ⚙️
//
//  La modalità NON viene salvata: la tengo in una @State, che si azzera quando l'app
//  viene chiusa. Così a ogni apertura l'app chiede di nuovo "cosa vuoi fare oggi?".
//  📌 Nota per me: se esco dall'app con il tasto Home e rientro subito, iOS la tiene
//  ancora aperta in memoria → NON richiede. Ed è giusto: se stavo usando il timer
//  di studio, non voglio ritrovarmi alla schermata iniziale.
//
//  Per cambiare modalità senza chiudere l'app: ⚙️ Impostazioni → "Cambia modalità".
//

import SwiftUI

struct RootView: View {
    /// La modalità scelta nella schermata iniziale (nil = non ancora scelta → schermata iniziale)
    @State private var mode: AppMode? = nil
    /// La sezione aperta in ognuna delle due modalità.
    /// Stanno QUI perché quando cambi lingua l'app viene ridisegnata da capo
    /// (vedi .id(language) più sotto) e senza questo torneresti sempre alla prima sezione.
    @State private var studyTab: StudyTab = .today
    @State private var plannerTab: PlannerTab = .day

    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    /// La lingua scelta dall'utente (di default italiano)
    @AppStorage(L10n.languageKey) private var language = AppLanguage.italian.rawValue

    var body: some View {
        Group {
            switch mode {
            case .study:
                StudyModeView(tab: $studyTab, onChangeMode: backToStart)
                    .transition(.opacity)
            case .planner:
                PlannerModeView(tab: $plannerTab, onChangeMode: backToStart)
                    .transition(.opacity)
            case nil:
                // La schermata iniziale: "Study" oppure "Plan my day"
                OnboardingView { chosen in
                    // ogni volta si parte dalla prima sezione della modalità scelta
                    studyTab = .today
                    plannerTab = .day
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation(.easeInOut) { mode = chosen }
                }
                .transition(.opacity)
            }
        }
        // Quando cambia la lingua ricreo tutte le viste: così ogni tr("…", "…") viene rifatto
        .id(language)
        // Date, DatePicker ecc. nella stessa lingua dei testi
        .environment(\.locale, AppLanguage(rawValue: language)?.locale ?? L10n.locale)
        .tint(Theme.main)
        // Il design Ube night è solo scuro
        .preferredColorScheme(.dark)
    }

    /// Torna alla schermata iniziale (da Impostazioni → "Cambia modalità")
    private func backToStart() {
        withAnimation(.easeInOut) { mode = nil }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
