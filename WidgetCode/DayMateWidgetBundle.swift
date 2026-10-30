//
//  DayMateWidgetBundle.swift
//  DayMateWidget
//
//  Created by Antonio Carotenuto.
//
//  Il punto di partenza dell'estensione widget (come DayMateApp lo è per l'app).
//  Per ora contiene solo la Live Activity del timer; un domani potrei aggiungere qui
//  anche un widget per la Home ("Next tiny step").
//

import WidgetKit
import SwiftUI

// @main = "parti da qui" (ma per l'estensione, non per l'app)
@main
struct DayMateWidgetBundle: WidgetBundle {
    var body: some Widget {
        StudyLiveActivity()
    }
}
