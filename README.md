# 🦥 DayMate

**Autore:** Antonio Carotenuto ([@entoni00-dev](https://github.com/entoni00-dev)) · Apple Foundation Program

> *"Help students overcome the anxiety of starting to study, and take real breaks instead of endless scrolling."*

App iOS in **SwiftUI + SwiftData** per la challenge dell'Apple Foundation Program (ex **Primo Passo**).
Niente social, niente account, niente server: **tutto resta sul telefono**.
L'app parte in **italiano**; l'utente può passare all'**inglese** dalla prima schermata (🇮🇹 IT / 🇬🇧 EN) o da Impostazioni → Lingua.

---

## ▶️ Come aprirla e farla partire

1. Scompatta lo zip e apri **`DayMate.xcodeproj`** con **Xcode 16 o successivo**.
2. In alto scegli un simulatore (es. *iPhone 16*) e premi **▶︎ Run** (`⌘R`).
3. **Per provarla sul tuo iPhone:**
   - collega l'iPhone al Mac;
   - seleziona il target *DayMate* → tab **Signing & Capabilities** → in **Team** scegli il tuo Apple ID;
   - se serve, cambia il *Bundle Identifier* (ora è `it.foundation.daymate`);
   - sull'iPhone: *Impostazioni → Generali → VPN e gestione dispositivi* → autorizza lo sviluppatore.

Requisiti: **iOS 17+**. Il Tutor AI si attiva da solo su iOS 26 con Apple Intelligence.

> ℹ️ Il Bundle Identifier è cambiato: DayMate si installa come **app nuova**, accanto a Primo Passo. I dati di Primo Passo non vengono trasferiti.

---

## 🆕 Cosa cambia in DayMate (v2 → DayMate)

1. **Nuova grafica dalle schermate Sketch**: palette miele / marrone / ruggine / lilla, bottoni a capsula, barra in alto, cerchi decorativi.
2. **Il bradipo**: mascotte in 14 pose (vedi sotto come sostituirlo con le illustrazioni originali).
3. **Due modi di usare l'app, scelti una volta all'inizio** (come entrare "da utente" o "da titolare"): dopo la presentazione, "Come vuoi usare DayMate?"
   - 📚 **Studio** → barra in alto: Esami · Dubbi · Coach · Progressi (+ Esame / + Dubbio)
   - 🗓️ **Planner** → barra in alto: Giorno · Settimana · Scadenze (+ Attività / + Scadenza)
   - Dalla seconda apertura l'app parte direttamente nella modalità scelta. Si cambia da ⚙️ Impostazioni → Modalità; i dati restano.
   - Collegamenti: se usi Studio, i passi di oggi e le date d'esame compaiono anche nel Planner.
   - **Dubbi**: si aggiungono quando vuoi (Dubbi → + Dubbio, o dal menu ••• di un esame), non solo durante un blocco.
4. **4 umori invece di 3**: Great, Sleepy, Stuck, Stressed (vedi tabella sotto).
5. **Planner** (nuovo): cose da fare del giorno + i passi di studio già presi dal piano, e l'acqua (8 bicchieri, modificabile nelle Impostazioni).
6. **New Exam ridisegnato**: gli argomenti sono "chip" (tocca per pagine e difficoltà), la pista 🐢 → 🐇 sceglie il ritmo giornaliero e la card dice subito se il piano ci sta.
7. **Cose nuove di iOS 17**: suggerimenti con **TipKit** (Esami, Dubbi, Planner), **SF Symbols animati** (`.symbolEffect`), SwiftData, `@Observable`; e il **Tutor AI on-device** con Foundation Models (iOS 26).
8. **Codice scritto per essere capito**: commenti in prima persona in ogni file (📌 Nota per me, 🐛 Problema che ho incontrato), niente trucchi avanzati dove non servono.
9. **Italiano (predefinito) + inglese a scelta dell'utente**, con `tr("English", "Italiano")` (file `Design/L10n.swift`). Cambiando lingua l'app si ridisegna subito e resti nella schermata in cui eri.
8. Coach, Progress e Impostazioni restano tutti, ridisegnati.

## 🦥 Usare le illustrazioni originali di Sketch

Il bradipo è in `Assets.xcassets` → cartella **Sloth**, un PNG per ogni posa (versioni provvisorie ridisegnate dalle schermate). Per usare i disegni originali di Sketch:

1. In Sketch esporta ogni bradipo come **PNG @3x** (o PDF) con sfondo trasparente.
2. Trascinali in `Assets.xcassets/Sloth` sopra quelli esistenti, con **questi nomi esatti**:

| Nome asset | Dove compare |
|---|---|
| `sloth_hanging` | First Page (appeso al ramo) |
| `sloth_reading` | card Study, timer in corso |
| `sloth_calendar` | card Plan |
| `sloth_pointing` | card dell'esame |
| `sloth_thinking` | New Exam, esami vuoti |
| `sloth_book` | timer pronto (tiene il libro) |
| `sloth_hat` | pausa |
| `sloth_waving` | Welcome back! |
| `sloth_drinking` | card dell'acqua |
| `sloth_head` | avatar ("Slooow", fumetti) |
| `sloth_great`, `sloth_sleepy`, `sloth_stuck`, `sloth_stressed` | tessere del Mood |

Non serve toccare il codice: `SlothView` mostra semplicemente `Image("sloth_…")`.

## 🔁 Il ciclo dell'app

```
Mood ─► [riscaldamento 2-3' → scelta] ─► TIMER (blocchi a rampa) ─► ⏸️ Time for a break!
        (solo Stuck / Stressed)             ▲                                  │
                                            │                                  ▼
                                 ▶️ Welcome back! ◄──────────── Take a real break (5', lunga ogni 4)

In ogni momento: "Stop for today" ─► umore di fine ─► riepilogo
```

| Umore | Riscaldamento | Blocchi di studio |
|---|---|---|
| 😊 Great | nessuno | 15' → 25' → 25'… |
| 😴 Sleepy | nessuno (prima un bicchiere d'acqua) | 10' → 10' → 15' → 20' → 25'… |
| 😣 Stressed | "leggi solo le prime righe" · 3 min | 10' → 15' → 20' → 25'… |
| 🧱 Stuck | un gesto fisico: "apri il libro" · 2 min | 5' → 10' → 15' → 25'… |

---

## 🗂️ Struttura del codice

```
DayMate/
├── App/DayMateApp.swift             → entry point + container SwiftData
├── Design/                          → lo stile di Sketch
│   ├── Theme.swift                  → colori e caratteri
│   ├── Components.swift             → bottoni a capsula, ‹ BackPill, card, fumetto…
│   ├── L10n.swift                   → lingua scelta dall'utente (IT di default): tr("…", "…")
│   ├── SlothView.swift              → il bradipo (immagini in Assets/Sloth)
│   ├── WeekStrip, TortoiseTrack, SlothRing → settimana, pista 🐢→🐇, anello del timer
│   ├── TopTabBar.swift              → la barra in alto delle modalità Studio / Planner
├── Models/                          → cosa viene SALVATO (Exam, StudyStep, StudySession, Doubt,
│                                      PlannerTask, WaterLog) + Mood, StudyKinds, BreakActivity
├── Logic/                           → piano di studio, ritmo, coach, tutor AI, notifiche, suoni
├── Resources/                       → suoni + nome dell'app per lingua
└── Views/
    ├── Onboarding/                  → "Slooow", presentazione e scelta della modalità
    ├── Study/StudyModeView          → modalità Studio con la barra in alto
    ├── Planner/                     → modalità Planner: Giorno, Settimana, Scadenze
    ├── Exams/                       → esami, nuovo esame, dettaglio
    ├── Session/                     → Mood → Timer → Break → Welcome back (MVVM)
    ├── Coach/ Stats/ Settings/
    └── Components/                  → programma della giornata, StatTile…
```

**Scelte architetturali:**
- La sessione segue il pattern **MVVM**: `StudySessionModel` (@Observable) contiene stato e decisioni, le viste mostrano e comunicano le scelte con closure.
- Il **piano non viene salvato ma ricalcolato** ogni volta dai passi rimasti: così si adatta da solo e non genera "ritardi" che fanno sentire in colpa. Anche il Planner lo legge da lì.
- Il **Tutor AI** è isolato dietro `#if canImport(FoundationModels)` + `@available(iOS 26, *)`: l'app compila e gira anche su iOS 17.
- **Solo modalità chiara**: la palette di Sketch è pensata per sfondi chiari.

## 💡 Idee aggiunte rispetto al prompt iniziale

1. **Check-out dell'umore** a fine sessione → l'app ti mostra, con i tuoi dati, in quante sessioni ti sentivi meglio *dopo* aver iniziato.
2. **"È troppo? Rendilo più piccolo"** → se anche il passo proposto spaventa, lo riduci con un tocco, senza rifare il check-in.
3. **Ritmo consigliato** → "bastano ~15 minuti al giorno": il totale spaventa, la quota giornaliera no.
4. **Notifiche locali** → puoi bloccare il telefono e metterlo via: ti avvisa l'app.
5. **Timer basato sulla data di fine** → resta preciso anche se iOS sospende l'app.
6. **Bottone onesto "In realtà ho preso il telefono 🙈"** → nessun rimprovero, ma le statistiche restano sincere.
7. **"Giorni in cui hai iniziato" invece della streak** → le streak quando si rompono generano senso di colpa.
8. **"Next tiny step" sulla card dell'esame** → apri l'app (modalità Studio) e con un tocco si parte. "Slooow" e la scelta della modalità compaiono solo al primo avvio, per non aggiungere tocchi ogni volta.
9. **Incolla l'indice del programma** → nel foglio "New topic", separando i nomi con virgole crei tanti argomenti in una volta.

---

## ⚠️ Limiti noti (da dire onestamente in presentazione)

- L'app **non legge il materiale**: le stime partono dalle pagine (3-7 min/pagina) e poi si calibrano sui tuoi tempi reali. Le pagine le devi contare tu.
- Le pause "senza telefono" sono **auto-dichiarate**: l'app si fida dell'utente.
- Il Tutor AI usa un modello piccolo: ottimo per spiegare e interrogare, ma può sbagliare sui fatti.
- iOS può ritardare le notifiche se il telefono è in modalità Risparmio energetico o Full Immersion.

- Le traduzioni usano `tr()` e non uno String Catalog, perché la lingua la sceglie l'utente dentro l'app (lo String Catalog segue la lingua del telefono). Per una terza lingua bisognerebbe estendere `tr()`.
- I passi di un esame vengono scritti nella lingua attiva al momento della creazione: cambiando lingua dopo, quei titoli restano com'erano.

## 🚀 Possibili sviluppi

- **AlarmKit** (iOS 26): una vera sveglia di sistema che suona anche in modalità Full Immersion.
- Foto degli appunti → quiz con l'AI (VisionKit + Foundation Models).
- Widget / Live Activity con il timer sulla schermata di blocco.
- **Screen Time API** (FamilyControls) per silenziare i social durante i blocchi.

---

© 2026 Antonio Carotenuto. Tutti i diritti riservati.
