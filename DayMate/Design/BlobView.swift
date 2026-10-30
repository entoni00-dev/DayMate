//
//  BlobView.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  🫘 Il Blob, la mascotte di DayMate (pagina "Mascot" del file Sketch).
//
//  Le 8 pose sono immagini PNG in Assets.xcassets → cartella "Mascot".
//  Ognuna si chiama "blob_" + il nome della posa (es. "blob_reading").
//
//  📌 Nota per me: per aggiornare un disegno basta esportarlo da Sketch come PNG
//  con sfondo trasparente e trascinarlo sopra quello vecchio, con lo STESSO nome.
//  Ho usato un enum per non scrivere i nomi a mano: se sbaglio, Xcode me lo dice subito.
//

import SwiftUI

/// Le pose del Blob
enum BlobPose: String, CaseIterable {
    case hello       // saluta (schermata iniziale, "Welcome back!")
    case reading     // occhiali + libro (prossimo passo di studio)
    case cheer       // occhi a stella ("Nice work!")
    case ready       // sorride (umore "Ready")
    case tired       // zZ (umore "Tired")
    case stressed    // goccia di sudore (umore "Stressed")
    case stuck       // occhi a spirale (umore "Stuck")
    case pause       // cappellino (pausa)

    /// Il nome dell'immagine negli Assets
    var imageName: String {
        // "pause" nel codice, ma in Sketch la posa si chiama "break"
        // (break è una parola riservata di Swift, quindi non posso usarla come nome)
        self == .pause ? "blob_break" : "blob_" + rawValue
    }
}

struct BlobView: View {
    let pose: BlobPose

    var body: some View {
        Image(pose.imageName)
            .resizable()        // si adatta allo spazio che le do con .frame
            .scaledToFit()      // senza deformarsi
            .accessibilityHidden(true)   // è decorativa: VoiceOver la salta
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
        ForEach(BlobPose.allCases, id: \.self) { pose in
            VStack {
                BlobView(pose: pose).frame(height: 80)
                Text(pose.rawValue).font(.caption).foregroundStyle(Theme.secondary)
            }
        }
    }
    .padding()
    .background(Theme.background)
}
