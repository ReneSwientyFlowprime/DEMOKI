# DEMOKI – Fotos zu Referenzbelegen (RAP + Fiori Elements)

Fiori Elements App zum Hochladen beliebig vieler Fotos (jeweils mit
Pflicht-Kommentar) zu einem Referenzbeleg. Als Referenzbeleg kann verwendet
werden:

- **Transport** (LE-TRA)
- **Auslieferung** (LE)
- **Handling Unit** (EWM)

Das Backend ist als ABAP RESTful Application Programming Model (RAP)
Business Object umgesetzt, das Frontend ist eine generische
**Fiori Elements List Report / Object Page App** (OData V4), die komplett
aus den Backend-Annotationen generiert wird – kein eigener UI-Code.

## Architektur

```
backend/src/
├── ddl/
│   ├── zrefdoc_h.ddls.asddls        Tabellendefinition Header (CDS Table Entity)
│   ├── zrefdoc_photo.ddls.asddls    Tabellendefinition Fotos (CDS Table Entity)
│   ├── zrefdoc_typet.ddls.asddls    Texttabelle Belegart (CDS Table Entity)
│   ├── zi_refdoc.ddls.asddls        Interface View (root, BO-Ebene)
│   ├── zi_refdocphoto.ddls.asddls   Interface View (child, Foto inkl. Stream-Feld)
│   ├── zi_refdoctype.ddls.asddls    Werthilfe Belegart
│   ├── zc_refdoc.ddls.asddls        Consumption/Projection View (root)
│   └── zc_refdocphoto.ddls.asddls   Consumption/Projection View (child)
├── ddlx/
│   ├── zc_refdoc.ddlx.asddlxs       UI-Annotationen List Report / Object Page
│   └── zc_refdocphoto.ddlx.asddlxs  UI-Annotationen Foto-Tabelle (Upload, Kommentar)
├── bdef/
│   ├── zi_refdoc.bdef.asbdef        Behavior Definition (managed, BO-Ebene)
│   ├── zi_refdocphoto.bdef.asbdef   Behavior Definition (managed, BO-Ebene)
│   ├── zc_refdoc.bdef.asbdef        Projection Behavior Definition
│   └── zc_refdocphoto.bdef.asbdef   Projection Behavior Definition
├── srv/
│   └── zui_refdoc_photo.srvd.asddls Service Definition
└── reports/
    └── zr_refdoc_type_init.prog.abap  Einmal-Report: Stammdaten Belegart

app/
└── webapp/                          Fiori Elements App (manifest-getrieben)
    ├── manifest.json
    ├── Component.js
    ├── i18n/i18n.properties
    └── index.html
```

### Datenmodell

| Tabelle             | Zweck                                    | Schlüsselfelder                 |
|----------------------|-------------------------------------------|-----------------------------------|
| `ZRefDoc`            | Header: ein Referenzbeleg                 | `refdoc_uuid`                     |
| `ZRefDocPhoto`       | Item: n Fotos je Referenzbeleg (Composition) | `photo_uuid`, FK `refdoc_uuid`  |
| `ZRefDocTypeT`       | Sprachabhängige Texte für die Belegart    | `ref_type`, `spras`               |

`ZRefDoc.ref_type` unterscheidet die drei Belegarten:
`T` = Transport (LE-TRA), `D` = Auslieferung (LE), `H` = Handling Unit (EWM).
`ZRefDoc.ref_number` nimmt die jeweilige Belegnummer auf (z. B. `TKNUM`,
`VBELN` bzw. die HU-Nummer aus EWM). Eine feste Verknüpfung/Prüfung gegen
die Ursprungsbelege (z. B. `VTTK`, `LIKP`, `/SCWM/HU_HDR` bzw. die
entsprechenden CDS-Views) ist bewusst nicht fest verdrahtet, damit die App
in unterschiedlichen Systemlandschaften (ERP/S4 on-prem, dezentrales EWM,
BTP) einsetzbar bleibt. Falls gewünscht, lässt sich pro Belegart eine
Prüfung/Wertehilfe auf den jeweiligen Originalbeleg leicht ergänzen (siehe
Erweiterungspunkte unten).

`ZRefDocPhoto.photo` ist das eigentliche Bild (`Semantics.largeObject`,
inkl. `MimeType`/`FileName`), sodass die App automatisch einen
Datei-Upload-Control (Kamera/Datei wählen) rendert. `ZRefDocPhoto.comment`
ist über die Behavior Definition (`field (mandatory) Comment`) als
Pflichtfeld hinterlegt.

### RAP Business Object

- **Root**: `ZI_RefDoc` / Projektion `ZC_RefDoc` – *managed*, kein Draft
  (bewusste Entscheidung: der Upload-Flow ist ein direkter Save-Vorgang,
  kein mehrstufiger Bearbeitungsprozess; Draft kann bei Bedarf über den
  ADT-Schnellzugriff "Draft aktivieren" ergänzt werden).
- **Child**: `ZI_RefDocPhoto` / Projektion `ZC_RefDocPhoto` – wird
  ausschließlich über die Komposition `_Photo` des Headers angelegt
  (`association _Photo { create; }`), analog zu Positionen in einem
  klassischen Kopf/Positions-BO.
- Ersteller/Änderer/Zeitstempel werden automatisch über die Semantik-
  Annotationen (`@Semantics.user.createdBy`, `@Semantics.systemDateTime.*`)
  vom RAP-Framework gepflegt – kein eigener Behavior-Implementierungscode
  nötig.
- `LocalLastChangedAt` dient als ETag-Feld für optimistisches Sperren.

### Fiori Elements App

Der Service `ZUI_REFDOC_PHOTO` wird als List Report (`RefDoc`) mit
Object Page dargestellt. Auf der Object Page erscheint die Foto-Tabelle
als editierbare Inline-Tabelle: pro Zeile ein Upload-Feld (Foto), Dateiname
und das Pflichtfeld Kommentar. Beliebig viele Zeilen/Fotos können über
"Hinzufügen" ergänzt werden, da `_Photo` eine `[0..*]`-Komposition ist.

## Deployment

1. **DDIC/CDS-Objekte anlegen** (empfohlen: ADT, Paket + Transportauftrag
   nach Bedarf anlegen). Reihenfolge einhalten, da Abhängigkeiten bestehen:
   1. `ddl/zrefdoc_h.ddls.asddls`, `ddl/zrefdoc_photo.ddls.asddls`,
      `ddl/zrefdoc_typet.ddls.asddls` (Tabellen)
   2. `ddl/zi_refdoc.ddls.asddls`, `ddl/zi_refdocphoto.ddls.asddls`,
      `ddl/zi_refdoctype.ddls.asddls` (Interface Views)
   3. `ddl/zc_refdoc.ddls.asddls`, `ddl/zc_refdocphoto.ddls.asddls`
      (Projection Views)
   4. `ddlx/zc_refdoc.ddlx.asddlxs`, `ddlx/zc_refdocphoto.ddlx.asddlxs`
      (Metadaten-Erweiterungen)
   5. `bdef/zi_refdoc.bdef.asbdef`, `bdef/zi_refdocphoto.bdef.asbdef`,
      `bdef/zc_refdoc.bdef.asbdef`, `bdef/zc_refdocphoto.bdef.asbdef`
      (Behavior Definitions)
   6. `srv/zui_refdoc_photo.srvd.asddls` (Service Definition)

   > Hinweis: `define table entity` setzt ein ABAP-Cloud-fähiges System
   > voraus (SAP BTP ABAP Environment bzw. S/4HANA mit aktivierter
   > ABAP-Cloud-Entwicklung). Steht nur klassische DDIC-Entwicklung zur
   > Verfügung, können `ZRefDoc`, `ZRefDocPhoto` und `ZRefDocTypeT`
   > 1:1 mit denselben Feldern als klassische transparente Tabellen (SE11
   > bzw. ADT-Tabellen-Editor) angelegt werden; die restlichen Artefakte
   > bleiben unverändert gültig.

2. **Service Binding anlegen**: In ADT per Rechtsklick auf
   `ZUI_REFDOC_PHOTO` → *New Service Binding*, Bindungstyp
   **OData V4 – UI**, Namensvorschlag `ZUI_REFDOC_PHOTO_O4` übernehmen,
   danach *Publish*. (Service Bindings werden grundsätzlich über den
   ADT-Assistenten erzeugt, nicht als Textquelle gepflegt.)

3. **Stammdaten Belegart einspielen**: Report
   `reports/zr_refdoc_type_init.prog.abap` einmalig anlegen und ausführen,
   damit die Werthilfe für `ReferenceType` (Transport/Auslieferung/
   Handling Unit) mit deutschen und englischen Texten befüllt ist.

4. **Fiori Elements App bereitstellen**: Ordner `app/` in SAP Fiori
   Tools / Business Application Studio importieren (oder `npm install`
   lokal ausführen), `manifest.json` → `sap.app/dataSources/mainService/uri`
   ggf. an die tatsächliche Service-URL des veröffentlichten Service
   Bindings anpassen, anschließend über die Fiori-Tools-Deployment-
   Konfiguration (`fiori add deploy-config`) ins ABAP-Frontend-System bzw.
   den BTP HTML5-App-Host deployen, oder als lokale Preview mit
   `npm start` testen (Mock-/Proxy-Konfiguration je nach Zielsystem
   ergänzen).

## Erweiterungspunkte

- **Validierung der Belegnummer** gegen den Originalbeleg (z. B. `VTTK`,
  `LIKP`, EWM-HU): eigene Validierungsklasse in der Behavior Definition
  von `ZI_RefDoc` ergänzen (`validation ... on save { field ReferenceNumber; }`).
  Über `switch(ReferenceType)`-Logik in der Implementierungsklasse jeweils
  gegen die passende Quelle prüfen.
- **Maximale Dateigröße / erlaubte Formate**: `acceptableMimeTypes` in
  `zi_refdocphoto.ddls.asddls` anpassen; eine harte Größenprüfung lässt
  sich über eine Validierung auf `Photo` (Länge des Byte-Strings) ergänzen.
- **Berechtigungen**: aktuell `authorization master( instance )` bzw.
  `authorization dependent by _RefDoc` – bei Bedarf ein PFCG-Berechtigungs-
  objekt ergänzen und in der Behavior-Implementierung auswerten.
- **Draft/Genehmigungsworkflow**: falls Fotos vor dem endgültigen Speichern
  noch bearbeitet werden sollen, Draft über den ADT-Schnellzugriff auf der
  Behavior Definition aktivieren.
