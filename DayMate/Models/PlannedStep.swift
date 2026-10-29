//
//  PlannedStep.swift
//  DayMate
//
//  Created by Antonio Carotenuto.
//
//  Il passo che l'utente sta per fare IN QUESTO MOMENTO.
//
//  Perché non uso direttamente StudyStep?
//  Perché non tutti i passi sono "di studio": se sei bloccato, il primo passo è
//  tipo "apri il libro" — un riscaldamento che non è salvato nel database
//  e non conta nei progressi dell'esame. Quindi:
//    - step != nil  → passo vero, collegato a un StudyStep salvato
//    - step == nil  → passo di riscaldamento (warm-up)
//

import Foundation

struct PlannedStep {
    let text: String
    let minutes: Int
    let step: StudyStep?

    var isWarmUp: Bool { step == nil }
}
