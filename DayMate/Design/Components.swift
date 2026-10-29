//
//  Components.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  I "mattoncini" grafici ripetuti in tutte le schermate di Sketch:
//   - PillButtonStyle → i bottoni a capsula (scuro "Start" / miele "Have a break")
//   - BackPill        → il bottoncino "‹ Home" in alto a sinistra
//   - ScreenHeader    → etichetta ruggine + titolo grande ("Math - step 3 of 6" / "Read Ch. 2")
//   - DecoCircles     → i cerchi decorativi (mezzo sole giallo in alto a destra)
//   - dmCard()        → le card arrotondate
//   - CountPill       → la pillola scura "in 9 days"
//   - SlothBubble     → il fumetto tratteggiato con il bradipo ("Got it: …")
//

import SwiftUI
import UIKit

// MARK: - Bottoni a capsula

struct PillButtonStyle: ButtonStyle {
    enum Variant {
        case dark     // marrone scuro, testo bianco: azione principale
        case honey    // miele, testo bianco: azione secondaria / pausa
        case cream    // crema, testo scuro: azioni piccole ("+1 glass")
        case lilac    // lilla: tutto ciò che è "Plan"
    }

    var variant: Variant = .dark
    var height: CGFloat = 58
    /// false = largo quanto il testo (es. "LET'S GO!")
    var expands = true

    // makeBody è la funzione che ogni ButtonStyle deve avere: riceve il bottone
    // ("configuration") e restituisce come deve apparire
    func makeBody(configuration: Configuration) -> some View {
        PillBody(configuration: configuration, variant: variant, height: height, expands: expands)
    }

    /// 🐛 Problema che ho incontrato: volevo che il bottone diventasse semi-trasparente
    /// quando è disattivato (.disabled), ma dentro ButtonStyle non riuscivo a leggerlo.
    /// Soluzione: una vista separata che legge \.isEnabled dall'environment.
    private struct PillBody: View {
        let configuration: ButtonStyleConfiguration
        let variant: Variant
        let height: CGFloat
        let expands: Bool
        @Environment(\.isEnabled) private var isEnabled

        private var background: Color {
            switch variant {
            case .dark:  return Theme.cocoa
            case .honey: return Theme.honey
            case .cream: return Theme.cream
            case .lilac: return Theme.lilac
            }
        }

        private var foreground: Color {
            switch variant {
            case .dark, .honey, .lilac: return .white
            case .cream: return Theme.ink
            }
        }

        var body: some View {
            configuration.label
                .font(.dmButton)
                .foregroundStyle(foreground)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, expands ? 16 : 22)
                .frame(maxWidth: expands ? .infinity : nil, minHeight: height)
                .background(background, in: Capsule())
                .overlay(Capsule().strokeBorder(.black.opacity(0.07), lineWidth: 1))
                .shadow(color: .black.opacity(variant == .cream ? 0.08 : 0.16), radius: 5, y: 3)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .opacity(isEnabled ? 1 : 0.45)
                .animation(.spring(response: 0.3), value: configuration.isPressed)
        }
    }
}

/// Link testuale discreto ("Stop for today", "Skip")
struct TextLinkStyle: ButtonStyle {
    var color: Color = Theme.mute

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(color)
            .opacity(configuration.isPressed ? 0.5 : 1)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
    }
}

// MARK: - "‹ Home"

struct BackPill: View {
    let title: String
    /// Azione personalizzata; se nil torna indietro nella navigazione
    var systemImage = "chevron.left"
    var action: (() -> Void)? = nil

    // dismiss() chiude questa schermata (o il foglio) e torna indietro
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            Haptics.tap()
            if let action { action() } else { dismiss() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                Text(title)
                    .font(.system(.body, weight: .medium))
            }
            .foregroundStyle(Theme.rust)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.pillGray, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tr("Back to \(title)", "Torna a \(title)"))
    }
}

// MARK: - Etichetta + titolo

struct ScreenHeader: View {
    var eyebrow: String? = nil
    let title: String
    var subtitle: String? = nil
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.dmEyebrow)
                    .foregroundStyle(Theme.rust)
            }
            Text(title)
                .font(.dmTitle)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.mute)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
    }
}

// MARK: - Cerchi decorativi (il "mezzo sole" di Sketch)

struct DecoCircles: View {
    var color: Color = Theme.honey
    /// Il cerchio crema a sinistra, a metà schermo (schermate del timer)
    var showSideCircle = false

    var body: some View {
        Color.clear
            .overlay(alignment: .topTrailing) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(color)
                        .frame(width: 190, height: 190)
                        .offset(x: 95, y: -10)
                    Circle()
                        .fill(Theme.stone.opacity(0.75))
                        .frame(width: 96, height: 96)
                        .offset(x: -40, y: 115)
                }
            }
            .overlay(alignment: .topLeading) {
                if showSideCircle {
                    Circle()
                        .fill(Theme.sand.opacity(0.7))
                        .frame(width: 110, height: 110)
                        .offset(x: -60, y: 470)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Card

extension View {
    /// Card arrotondata. `color` = sfondo (bianco di default)
    func dmCard(_ color: Color = .white, radius: CGFloat = 26, padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(.black.opacity(0.05), lineWidth: 1))
            .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    /// Sfondo standard delle schermate + barra di navigazione nascosta
    /// (il "‹ Home" lo disegno io con BackPill, come in Sketch)
    func dmScreen() -> some View {
        self
            .background(Theme.paper.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }

    /// Come dmScreen(), ma solo se la vista è una schermata a sé.
    /// Quando è "incorporata" in uno spazio (Studio / Planner) lo sfondo lo mette lo spazio.
    @ViewBuilder
    func dmScreen(standalone: Bool) -> some View {
        if standalone { self.dmScreen() } else { self }
    }
}

// MARK: - Pillola "in 9 days"

struct CountPill: View {
    let text: String
    var color: Color = Theme.cocoa

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color, in: Capsule())
    }
}

// MARK: - Fumetto tratteggiato con il bradipo

struct SlothBubble: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            SlothView(pose: .head)
                .frame(width: 42, height: 42)
                .background(Theme.cream, in: Circle())
            Text(text)
                .font(.subheadline.italic())
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.sand, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.mute.opacity(0.5),
                                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])))
    }
}

// MARK: - Checkbox quadrata (Planner e passi)

struct SquareCheck: View {
    let isOn: Bool
    var tint: Color = Theme.ink

    var body: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .strokeBorder(isOn ? tint : Theme.mute, lineWidth: 1.5)
            .background(RoundedRectangle(cornerRadius: 4).fill(isOn ? tint : .clear))
            .overlay {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 20, height: 20)
    }
}

// MARK: - Swipe indietro
//
// 📌 Nota per me: questo pezzo è UIKit (il "vecchio" framework sotto SwiftUI).
// L'ho trovato cercando "swipe back hidden navigation bar SwiftUI": è una soluzione
// molto usata. Non serve capirlo tutto: dice al navigatore "lascia fare lo swipe
// indietro anche se la barra di navigazione è nascosta, purché ci sia una schermata a cui tornare".
//
// Nascondendo la barra di navigazione iOS disattiva anche lo "swipe da sinistra"
// per tornare indietro. Questa estensione lo riattiva (trucco molto diffuso).

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

// MARK: - Selettore della lingua (IT / EN)

/// Due pillole affiancate: 🇮🇹 IT | 🇬🇧 EN. Salva la scelta in UserDefaults:
/// RootView se ne accorge e ridisegna tutta l'app nella nuova lingua.
struct LanguageToggle: View {
    // @AppStorage salva un valore semplice nelle impostazioni del telefono (UserDefaults)
    @AppStorage(L10n.languageKey) private var language = AppLanguage.italian.rawValue

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppLanguage.allCases) { option in
                let isOn = language == option.rawValue
                Button {
                    guard !isOn else { return }
                    Haptics.tap()
                    // withAnimation: il cambiamento avviene con un'animazione invece che di colpo
                    withAnimation(.snappy) { language = option.rawValue }
                } label: {
                    Text("\(option.flag) \(option.shortName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isOn ? .white : Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(isOn ? Theme.cocoa : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.name)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Theme.pillGray, in: Capsule())
    }
}
