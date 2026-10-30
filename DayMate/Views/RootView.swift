//
//  RootView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La vista "radice": decide cosa mostrare.
//
//  @AppStorage salva un valore semplice in UserDefaults (sempre sul telefono).
//  Va benissimo per flag e impostazioni; per i dati veri uso SwiftData.
//
//  🧭 Come si entra nell'app:
//
//   PRIMA VOLTA:  schermata iniziale "DayMate — One tiny step at a time"
//                          │
//              ┌───────────┴──────────────┐
//              ▼                          ▼
//   📚 MODALITÀ STUDIO              🗓️ MODALITÀ PLANNER
//   [ Oggi | Dubbi | Coach | Progressi ]   [ Giorno | Settimana | Scadenze ]
//
//   DALLA SECONDA VOLTA: si apre direttamente la modalità scelta.
//   Per cambiarla: ⚙️ Impostazioni → Modalità (come "uscire ed entrare" con un altro profilo).
//

import SwiftUI

/// Le schermate raggiungibili dalla barra in alto di entrambe le modalità
enum AppRoute: Hashable {
    case settings
}

struct RootView: View {
    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    @AppStorage(AppSettings.hasSeenOnboardingKey) private var hasSeenOnboarding = false
    /// La modalità scelta all'inizio ("" = non ancora scelta)
    @AppStorage(AppMode.storageKey) private var modeRaw = ""
    /// La lingua scelta dall'utente (di default italiano)
    @AppStorage(L10n.languageKey) private var language = AppLanguage.italian.rawValue
    /// Il percorso di navigazione sta QUI: quando cambi lingua l'app viene ridisegnata
    /// da capo, ma resti nella schermata in cui eri (es. Impostazioni).
    @State private var path = NavigationPath()

    private var mode: AppMode? { AppMode(rawValue: modeRaw) }

    var body: some View {
        Group {
            if hasSeenOnboarding, let mode {
                switch mode {
                case .study:
                    StudyModeView(path: $path)
                        .transition(.opacity)
                case .planner:
                    PlannerModeView(path: $path)
                        .transition(.opacity)
                }
            } else {
                // La schermata iniziale: "Study" oppure "Plan my day"
                OnboardingView { chosen in
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation(.easeInOut) {
                        modeRaw = chosen.rawValue
                        hasSeenOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        // Quando cambia la lingua ricreo tutte le viste: così ogni tr("…", "…") viene rifatto
        .id(language)
        // Cambiando modalità si riparte dalla sua prima schermata
        .onChange(of: modeRaw) { _, _ in path = NavigationPath() }
        // Date, DatePicker ecc. nella stessa lingua dei testi
        .environment(\.locale, AppLanguage(rawValue: language)?.locale ?? L10n.locale)
        .tint(Theme.main)
        // Il design Ube night è solo scuro
        .preferredColorScheme(.dark)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
