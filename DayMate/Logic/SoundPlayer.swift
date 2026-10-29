//
//  SoundPlayer.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  La "sveglia" di fine blocco e di fine pausa.
//
//  Ho creato due suoni diversi (in Resources/Sounds), così si capisce cosa sta
//  succedendo anche senza guardare lo schermo:
//   🔔 pausa.wav  → tre note che scendono, morbide  = "rilassati"
//   🔔 studio.wav → arpeggio che sale, più energico = "si riparte"
//
//  Uso la categoria audio .playback: il suono si sente anche con l'interruttore
//  silenzioso attivo, come una sveglia. Si può disattivare dalle Impostazioni.
//

import AVFoundation

enum AlarmSound: String {
    case pause = "pausa"
    case study = "studio"

    /// Nome del file, usato anche come suono delle notifiche
    var fileName: String { rawValue + ".wav" }
}

final class SoundPlayer {

    static let shared = SoundPlayer()
    private init() {}

    private var player: AVAudioPlayer?

    /// Suona l'avviso. `repeats` = quante volte in tutto (come una sveglia che insiste un po').
    func play(_ sound: AlarmSound, repeats: Int = 3) {
        guard AppSettings.soundEnabled else { return }
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            print("⚠️ Suono non trovato: \(sound.fileName)")
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            // .mixWithOthers: non interrompo la musica che l'utente sta ascoltando
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)

            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = max(0, repeats - 1)
            player?.play()
        } catch {
            print("⚠️ Errore audio: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
