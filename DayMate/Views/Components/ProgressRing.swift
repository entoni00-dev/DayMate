//
//  ProgressRing.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Anello di progresso semplice (stile "Attività" di Apple Watch).
//

import SwiftUI

struct ProgressRing: View {
    /// Da 0 a 1
    var progress: Double
    var color: Color = Theme.honey
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

// Anteprima per il canvas di Xcode (non finisce nell'app)
#Preview {
    ProgressRing(progress: 0.65, lineWidth: 16)
        .frame(width: 160, height: 160)
        .padding()
}
