//
//  Components.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  I "mattoncini" che si ripetono in tutte le schermate Ube night:
//
//   PrimaryButtonStyle  → il bottone viola grande ("Start next step", "Add")
//   SmallButtonStyle    → il bottone viola piccolo ("▶ Start · 5 min")
//   QuietButtonStyle    → il link grigio ("Not now")
//   SectionHeader       → le etichette maiuscole ("YOUR EXAMS", "TINY STEPS")
//   RowDivider          → la linea tra le righe di una lista
//   IconTile            → il quadratino con l'icona a sinistra delle righe
//   CheckCircle         → il cerchio dei passi: fatto ✓ / prossimo ◉ / da fare ○
//   ProgressRingView    → l'anello verde dei progressi
//   GlowRings           → i cerchi concentrici dietro il Blob
//   AddCircleButton     → il "+" tondo in alto a destra
//   HintCard            → la card con il Blob e un consiglio
//
//  📌 Nota per me: tenere questi pezzi in un file solo mi evita di riscrivere
//  gli stessi colori e arrotondamenti 50 volte. Se cambio qui, cambia ovunque.
//

import SwiftUI
import UIKit

// MARK: - Bottoni

/// Il bottone principale: viola, alto 56, testo scuro (come in Sketch)
struct PrimaryButtonStyle: ButtonStyle {
    // makeBody è la funzione che ogni ButtonStyle deve avere: riceve il bottone
    // ("configuration") e restituisce come deve apparire
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }

    /// 🐛 Problema che ho incontrato: volevo il bottone semi-trasparente quando è
    /// disattivato (.disabled), ma dentro ButtonStyle non riuscivo a leggerlo.
    /// Soluzione: una piccola vista separata che legge \.isEnabled dall'environment.
    private struct PrimaryButtonBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.dmButton)
                .foregroundStyle(Theme.background)     // testo scuro sul viola
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Theme.main, in: Capsule())
                .opacity(isEnabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)   // si "schiaccia" quando lo premo
                .animation(.spring(response: 0.3), value: configuration.isPressed)
        }
    }
}

/// Il bottone piccolo dentro le card ("▶ Start · 5 min")
struct SmallButtonStyle: ButtonStyle {
    var color: Color = Theme.main

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Theme.background)
            .padding(.horizontal, 18)
            .frame(height: 40)
            .background(color, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

/// Link discreto in grigio-lilla ("Not now", "Skip")
struct QuietButtonStyle: ButtonStyle {
    var color: Color = Theme.secondary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, weight: .medium))
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .padding(.vertical, 8)
            .contentShape(Rectangle())   // tutta l'area è toccabile, non solo le lettere
    }
}

// MARK: - Link in alto ("‹ Today", "Cancel", "Save")

struct TopLink: View {
    let title: String
    var showsChevron = false
    var bold = false
    var color: Color = Theme.lightMain
    var action: (() -> Void)? = nil

    // dismiss() chiude questa schermata e torna indietro
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            Haptics.tap()
            // se non mi passano un'azione, il link torna semplicemente indietro
            if let action { action() } else { dismiss() }
        } label: {
            Text(showsChevron ? "‹ " + title : title)
                .font(.system(.callout, weight: bold ? .bold : .medium))
                .foregroundStyle(color)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Titoli

/// Titolo grande + sottotitolo grigio, come "Today / Thursday 29 October"
struct ScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    var large = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(large ? .dmLargeTitle : .dmTitle)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Etichetta piccola + titolo + testo, per le schermate "di lettura" (Dubbi, Progressi…)
struct ScreenHeader: View {
    var eyebrow: String? = nil
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.accent)
            }
            Text(title)
                .font(.dmTitle)
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// "YOUR EXAMS", "TINY STEPS": etichetta maiuscola sopra una lista
struct SectionHeader: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.dmSection)
            .foregroundStyle(Theme.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .padding(.top, 8)
    }
}

/// La riga sottile tra due righe di una lista (parte dopo l'icona, come in iOS)
struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.highlight)
            .frame(height: 1)
            .padding(.leading, 56)
    }
}

// MARK: - Card

extension View {
    /// Sfondo da card: viola scuro con angoli arrotondati.
    /// `highlighted: true` = card in evidenza (es. "NEXT TINY STEP")
    func cardBackground(highlighted: Bool = false, radius: CGFloat = 20) -> some View {
        self.background(highlighted ? Theme.highlight : Theme.card,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Card "completa": margini interni + sfondo + angoli arrotondati
    func dmCard(_ color: Color = Theme.card, radius: CGFloat = 20, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Sfondo standard delle schermate + barra di navigazione di sistema nascosta
    /// (i link "‹ Today" li disegno io, come in Sketch)
    func dmScreen() -> some View {
        self
            .background(Theme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }

    /// Come dmScreen(), ma solo se la vista è una schermata a sé.
    /// Quando è "incorporata" in una modalità (Studio / Planner) lo sfondo lo mette la modalità.
    @ViewBuilder
    func dmScreen(standalone: Bool) -> some View {
        if standalone { self.dmScreen() } else { self }
    }
}

// MARK: - Icone e cerchi

/// Il quadratino 40×40 con un'icona SF Symbol (a sinistra delle righe)
struct IconTile: View {
    let systemName: String
    /// true = sfondo scuro su card viola (es. "Study" scelto)
    var inverted = false

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(inverted ? Theme.main : Theme.lightMain)
            .frame(width: 40, height: 40)
            .background(inverted ? Theme.background : Theme.highlight,
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

/// Il cerchio a sinistra dei passi
struct CheckCircle: View {
    enum Status { case done, next, todo }
    let state: Status

    var body: some View {
        ZStack {
            switch state {
            case .done:
                // verde pieno con la spunta scura
                Circle().fill(Theme.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.background)
            case .next:
                // anello verde con il pallino: "questo è il prossimo"
                Circle().strokeBorder(Theme.accent, lineWidth: 2)
                Circle().fill(Theme.accent).padding(6)
            case .todo:
                Circle().strokeBorder(Theme.secondary, lineWidth: 1.8)
            }
        }
        .frame(width: 24, height: 24)
    }
}

/// L'anello verde dei progressi (0…1)
struct ProgressRingView: View {
    var progress: Double
    var lineWidth: CGFloat = 5
    var color: Color = Theme.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.highlight, lineWidth: lineWidth)       // binario scuro
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))          // "taglio" il cerchio fino alla percentuale
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))                         // parte da "ore 12" invece che da "ore 3"
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

/// I cerchi concentrici verdi e tenui dietro il Blob (schermata iniziale, "Welcome back!")
struct GlowRings<Content: View>: View {
    var size: CGFloat = 300
    // @ViewBuilder: dentro { } posso mettere la vista da mostrare al centro
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Circle().stroke(Theme.accent.opacity(0.18), lineWidth: 1.5)
                .frame(width: size, height: size)
            Circle().stroke(Theme.accent.opacity(0.45), lineWidth: 1.5)
                .frame(width: size * 0.77, height: size * 0.77)
            Circle().fill(Theme.highlight)
                .frame(width: size * 0.53, height: size * 0.53)
            content()
                .frame(width: size * 0.42, height: size * 0.42)
        }
        .frame(width: size, height: size)
    }
}

/// Il "+" tondo in alto a destra
struct AddCircleButton: View {
    var accessibilityTitle: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 38, height: 38)
                .background(Theme.highlight, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
    }
}

/// La card con il Blob e un consiglio ("Keep steps small: 10–25 minutes each works best")
struct HintCard: View {
    let title: String
    let text: String
    var pose: BlobPose = .reading

    var body: some View {
        HStack(spacing: 12) {
            BlobView(pose: pose)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.text)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .cardBackground(highlighted: true, radius: 18)
    }
}

// MARK: - Selettore della lingua (IT / EN)

/// Due pillole: 🇮🇹 IT | 🇬🇧 EN. Salva la scelta in UserDefaults:
/// RootView se ne accorge e ridisegna tutta l'app nella nuova lingua.
struct LanguageToggle: View {
    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    @AppStorage(L10n.languageKey) private var language = AppLanguage.italian.rawValue

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    Haptics.tap()
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation(.snappy) { language = option.rawValue }
                } label: {
                    Text("\(option.flag) \(option.shortName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(language == option.rawValue ? Theme.background : Theme.text)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(language == option.rawValue ? Theme.main : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.name)
            }
        }
        .padding(4)
        .background(Theme.card, in: Capsule())
    }
}

// MARK: - Swipe indietro
//
// 📌 Nota per me: questo pezzo è UIKit (il "vecchio" framework sotto SwiftUI).
// L'ho trovato cercando "swipe back hidden navigation bar SwiftUI": è una soluzione
// molto usata. Dice al navigatore "lascia fare lo swipe indietro anche se la barra
// di navigazione è nascosta, purché ci sia una schermata a cui tornare".

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
