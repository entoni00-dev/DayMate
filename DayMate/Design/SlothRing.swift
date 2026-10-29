//
//  SlothRing.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il grande anello del timer di Sketch, con il bradipo al centro.
//   - fermo  → anello grigio pietra, il bradipo tiene il libro
//   - attivo → l'anello si riempie di giallo miele mentre il tempo passa
//

import SwiftUI

struct SlothRing: View {
    /// Quanto è pieno l'anello (0…1)
    var progress: Double
    var active: Bool
    var pose: SlothPose
    var lineWidth: CGFloat = 30

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.cream)
            Circle()
                .stroke(active ? Theme.honey.opacity(0.25) : Theme.stone, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Theme.honey, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            SlothView(pose: pose)
                .padding(lineWidth + 26)
        }
        // metà dello spessore dell'anello sta "fuori" dal cerchio: evito che venga tagliata
        .padding(lineWidth / 2)
        .aspectRatio(1, contentMode: .fit)
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    HStack {
        SlothRing(progress: 0, active: false, pose: .book)
        SlothRing(progress: 0.6, active: true, pose: .reading)
    }
    .padding()
}
