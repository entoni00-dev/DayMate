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

1. **Grafica "Ube night"** (file Sketch *DayMate-Ube-night*): tema scuro viola, verde menta per i progressi, liste in stile iOS, anelli concentrici.
2. **Il Blob**: la mascotte in 8 pose, esportate direttamente dal file Sketch.
3. **Due modi di usare l'app, scelti a ogni apertura** (come entrare "da utente" o "da titolare"): la schermata iniziale chiede sempre "Study" oppure "Plan my day".
   - 📚 **Studio** → barra in basso: Oggi · Dubbi · Progressi · Impostazioni (+ Esame / + Dubbio)
   - 🗓️ **Planner** → barra in basso: Giorno · Settimana · Scadenze · Impostazioni (+ Attività / + Scadenza)
   - La modalità non viene salvata: chiudendo l'app, alla riapertura la domanda ricompare. Senza chiudere l'app si torna alla scelta da ⚙️ Impostazioni → Cambia modalità; i dati restano.
   - Collegamenti: se usi Studio, i passi di oggi e le date d'esame compaiono anche nel Planner.
   - **Dubbi**: si aggiungono quando vuoi (Dubbi → + Dubbio, o dal menu ••• di un esame), non solo durante un blocco.
4. **4 umori invece di 3**: Great, Sleepy, Stuck, Stressed (vedi tabella sotto).
5. **Planner**: settimana, STUDY (passi d'esame del giorno + attività di studio), DUTIES & FREE TIME con orario, acqua. "Add to your day" con tipo (Studio / Impegno / Tempo libero), ora, durata e "È una scadenza".
6. **New exam come in Sketch**: materia, data e i piccoli passi scritti a mano (si riordinano trascinando ≡). Con "✨ Crea i passi per me" l'app genera un piano realistico da argomenti e pagine.
7. **Cose nuove di iOS 17**: suggerimenti con **TipKit** (Esami, Dubbi, Planner), **SF Symbols animati** (`.symbolEffect`), SwiftData, `@Observable`; e il **Tutor AI on-device** con Foundation Models (iOS 26).
8. **Codice scritto per essere capito**: commenti in prima persona in ogni file (📌 Nota per me, 🐛 Problema che ho incontrato), niente trucchi avanzati dove non servono.
9. **Italiano (predefinito) + inglese a scelta dell'utente**, con `tr("English", "Italiano")` (file `Design/L10n.swift`). Cambiando lingua l'app si ridisegna subito e resti nella schermata in cui eri.
10. **Coach tolto**: i consigli e "Cosa funziona davvero" non ci sono più. Il Tutor AI resta dentro i Dubbi ("Chiedi al tutor").

## 🫘 Il Blob (la mascotte)

Le 8 pose sono PNG in `Assets.xcassets/Mascot`, esportate dalla pagina *Mascot* del file Sketch:

| Nome asset | Dove compare |
|---|---|
| `blob_hello` | schermata iniziale, "Welcome back!" |
| `blob_reading` | card "Next tiny step" |
| `blob_cheer` | "Nice work!" a fine blocco, riepilogo |
| `blob_ready`, `blob_tired`, `blob_stressed`, `blob_stuck` | le 4 righe di "How do you feel?" |
| `blob_break` | pausa |

Per aggiornarle basta riesportarle da Sketch con lo stesso nome: `BlobView` mostra semplicemente `Image("blob_…")`.

## 🔁 Il ciclo dell'app

```
Today ─► "Start" ─► How do you feel? ─┬─ Ready / Tired ──────────────► TIMER ─► Break time ("Nice work!")
                                      ├─ Stuck ─► passo facilissimo 2' ─┘   ▲              │
                                      └─ Stressed ─► Break time subito      └─ Welcome back ◄┘

In ogni momento: "Basta" ─► umore di fine ─► riepilogo
```

| Umore | Cosa dice l'app | Cosa succede |
|---|---|---|
| 😊 Ready | Full step, 25 min | blocco intero subito |
| 😴 Tired | Shorter step, 10 min | 10' → 15' → 20' → 25' |
| 😣 Stressed | Start with a break | prima 5' di pausa, poi 10' → 15' → 20' |
| 🧱 Stuck | Easier step first | 2' di gesto minuscolo ("apri il libro"), poi 5' → 10' → 15' |

Nel timer: ⏸ mette in pausa, ✓ segna il passo fatto e passa al prossimo senza fermare il tempo.

---|---|---|
| 😊 Great | nessuno | 15' → 25' → 25'… |
| 😴 Sleepy | nessuno (prima un bicchiere d'acqua) | 10' → 10' → 15' → 20' → 25'… |
| 😣 Stressed | "leggi solo le prime righe" · 3 min | 10' → 15' → 20' → 25'… |
| 🧱 Stuck | un gesto fisico: "apri il libro" · 2 min | 5' → 10' → 15' → 25'… |

---

## 🏝️ Timer sulla schermata di blocco e nella Dynamic Island (Live Activity)

Durante un blocco di studio o una pausa, il conto alla rovescia si vede **senza sbloccare il telefono**: sulla schermata di blocco e, sugli iPhone 14 Pro e successivi, nella Dynamic Island. È il senso di "Phone down, one tiny step": guardi quanto manca senza finire su Instagram.

Il codice è già pronto, ma serve un secondo "pezzo" del progetto (un *Widget Extension*) che si aggiunge **una volta sola, a mano, in Xcode**:

1. **File → New → Target… → Widget Extension** → Next.
2. Product Name: `DayMateWidget`. Spunta **Include Live Activity**, togli *Include Configuration App Intent* → Finish. Se chiede *Activate scheme?* → **Cancel**.
3. Nella nuova cartella `DayMateWidget` **elimina** i file `.swift` che Xcode ha creato (*Move to Trash*).
4. Trascina dentro `DayMateWidget` i due file della cartella **`WidgetCode/`** (`DayMateWidgetBundle.swift` e `DayMateWidgetLiveActivity.swift`), con il target **DayMateWidgetExtension** spuntato.
5. Seleziona `DayMate/LiveActivity/StudyActivityAttributes.swift` → pannello a destra → **Target Membership** → spunta anche **DayMateWidgetExtension** (è il "contratto" che usano tutti e due).
6. Target **DayMateWidgetExtension** → General → **Minimum Deployments: iOS 17.0** e lo stesso *Team* dell'app.

Provala su un **iPhone vero**: avvia un blocco e blocca lo schermo. Nel simulatore la schermata di blocco funziona, la Dynamic Island solo sui simulatori "Pro".
Se le Live Activity sono disattivate (Impostazioni → DayMate → Attività in tempo reale) l'app funziona lo stesso, semplicemente senza.

Limite: dalla schermata di blocco si **vede** il timer ma non si può premere ⏸ o ✓. Per i bottoni servono gli *App Intents* (`LiveActivityIntent`): è il prossimo passo possibile.

## ♿️ Accessibilità

- **Testo grande (Dynamic Type):** righe e bottoni hanno un'altezza *minima* invece che fissa, così crescono con il testo. I titoli con misure di Sketch (38, 32, 44 pt) usano `@ScaledMetric`. Con le dimensioni "accessibilità" gli anelli della schermata iniziale e di "Welcome back" si rimpiccioliscono, così i bottoni restano sullo schermo. La settimana del Planner si ferma a XXXL, perché 7 quadratini devono stare in una riga.
- **VoiceOver:** il timer dice "Tempo rimasto, 3:42"; i cerchi dei passi dicono "Fatto / Prossimo / Da fare"; gli anelli dicono la percentuale; le gocce d'acqua dicono "bevuto / vuoto".
- **Aumenta contrasto:** il grigio-lilla dei testi secondari (#9890BF) sulle card chiare ha un contrasto di 4,35:1, appena sotto il 4,5:1 consigliato. Se l'utente attiva *Aumenta contrasto*, iOS usa da solo una versione più chiara (#CDC6EC, colore `SecondaryText` negli Assets).
- **Riduci movimento:** "Welcome back" compare senza animazione a molla.

## 🗂️ Struttura del codice

```
DayMate/
├── App/DayMateApp.swift             → entry point + container SwiftData
├── Design/                          → lo stile di Sketch
│   ├── Theme.swift                  → colori e caratteri
│   ├── Components.swift             → bottoni a capsula, ‹ BackPill, card, fumetto…
│   ├── L10n.swift                   → lingua scelta dall'utente (IT di default): tr("…", "…")
│   ├── BlobView.swift               → la mascotte (immagini in Assets/Mascot)
│   ├── WeekStrip.swift              → la settimana a quadratini
│   ├── ModeHeader.swift             → intestazione delle sezioni + colori della barra in basso
├── Models/                          → cosa viene SALVATO (Exam, StudyStep, StudySession, Doubt,
│                                      PlannerTask, WaterLog) + Mood, StudyKinds, BreakActivity
├── Logic/                           → piano di studio, ritmo, tutor AI, notifiche, suoni
├── Resources/                       → suoni + nome dell'app per lingua
├── LiveActivity/                    → dati e gestione del timer sulla schermata di blocco
└── Views/
    ├── Onboarding/                  → schermata iniziale: Study oppure Plan my day
    ├── Planner/                     → modalità Planner: Giorno, Settimana, Scadenze
    ├── Exams/                       → esami, nuovo esame, dettaglio
    ├── Study/                       → modalità Studio + "Today"
    ├── Session/                     → Mood → Timer → Break → Welcome back (MVVM)
    ├── Doubts/ Stats/ Settings/
    └── Components/                  → programma della giornata, StatTile…
```

**Scelte architetturali:**
- La sessione segue il pattern **MVVM**: `StudySessionModel` (@Observable) contiene stato e decisioni, le viste mostrano e comunicano le scelte con closure.
- Il **piano non viene salvato ma ricalcolato** ogni volta dai passi rimasti: così si adatta da solo e non genera "ritardi" che fanno sentire in colpa. Anche il Planner lo legge da lì.
- Il **Tutor AI** è isolato dietro `#if canImport(FoundationModels)` + `@available(iOS 26, *)`: l'app compila e gira anche su iOS 17.
- **Solo modalità scura**: la palette Ube night è pensata per lo sfondo notturno.

## 💡 Idee aggiunte rispetto al prompt iniziale

1. **Check-out dell'umore** a fine sessione → l'app ti mostra, con i tuoi dati, in quante sessioni ti sentivi meglio *dopo* aver iniziato.
2. **"È troppo? Rendilo più piccolo"** → se anche il passo proposto spaventa, lo riduci con un tocco, senza rifare il check-in.
3. **Ritmo consigliato** → "bastano ~15 minuti al giorno": il totale spaventa, la quota giornaliera no.
4. **Notifiche locali** → puoi bloccare il telefono e metterlo via: ti avvisa l'app.
5. **Timer basato sulla data di fine** → resta preciso anche se iOS sospende l'app.
6. **Bottone onesto "In realtà ho preso il telefono 🙈"** → nessun rimprovero, ma le statistiche restano sincere.
7. **"Giorni in cui hai iniziato" invece della streak** → le streak quando si rompono generano senso di colpa.
8. **"Next tiny step" in Today** → apri l'app (modalità Studio) e con un tocco si parte. La scelta della modalità compare solo al primo avvio, per non aggiungere tocchi ogni volta.
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
