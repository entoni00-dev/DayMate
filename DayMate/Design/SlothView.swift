//
//  SlothView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🦥 Il bradipo di DayMate, la nostra mascotte.
//
//  Le illustrazioni sono immagini PNG dentro Assets.xcassets → cartella "Sloth".
//  Ognuna si chiama "sloth_" + il nome della posa (es. "sloth_reading").
//
//  📌 Nota per me: per cambiare un disegno con quello originale di Sketch basta
//  esportarlo come PNG con sfondo trasparente e trascinarlo sopra quello vecchio
//  in Assets, con lo STESSO nome. Il codice non va toccato.
//
//  Ho usato un enum per le pose invece di scrivere i nomi a mano ("sloth_reding"…):
//  se sbaglio a scrivere una posa, Xcode me lo dice subito invece di mostrare
//  un'immagine vuota.
//

import SwiftUI

/// Tutte le pose del bradipo
enum SlothPose: String, CaseIterable {
    case reading     // occhiali + libro aperto (card Studio, timer in corso)
    case book        // tiene un libro chiuso (timer pronto a partire)
    case calendar    // calendario + occhiolino (Planner)
    case pointing    // indica (card dell'esame)
    case thinking    // pensieroso con zZ (nuovo esame)
    case waving      // saluta ("Bentornato!")
    case drinking    // beve acqua (card dell'acqua)
    case hanging     // appeso al ramo (prima schermata)
    case hat         // cappellino da pausa
    case head        // solo la testa (avatar)
    case great       // umore: alla grande
    case sleepy      // umore: assonnato
    case stuck       // umore: bloccato
    case stressed    // umore: stressato

    /// Il nome dell'immagine negli Assets
    var imageName: String {
        "sloth_" + rawValue
    }
}

struct SlothView: View {
    let pose: SlothPose

    var body: some View {
        Image(pose.imageName)
            .resizable()        // l'immagine si adatta allo spazio che le do con .frame
            .scaledToFit()      // senza deformarsi
            .accessibilityHidden(true)   // è decorativa: VoiceOver la salta
    }
}

#Preview {
    // Tutte le pose in una griglia, comodo per controllarle
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110))]) {
            ForEach(SlothPose.allCases, id: \.self) { pose in
                VStack {
                    SlothView(pose: pose)
                        .frame(height: 110)
                    Text(pose.rawValue)
                        .font(.caption)
                }
            }
        }
        .padding()
    }
}
