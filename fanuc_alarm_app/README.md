# Fanuc Robot Alarms

Application mobile Flutter pour consulter rapidement les codes d'alarme du contrôleur **Fanuc R-30iB** sur chantier.

## Fonctionnalités

- **11 290 codes d'alarme** issus de la documentation officielle Fanuc R-30iB
- **Recherche fuzzy** sur le code d'erreur — tape `srvo001` ou `srvo-001`, le tiret est ignoré ; les caractères n'ont pas besoin d'être consécutifs
- **Filtres par famille** (SRVO, INTP, ACAL, SERVO…) — SRVO en premier car c'est la famille la plus fréquente en pratique
- **Vue détail** par alarme : message, cause, remède
- **Badge de sévérité** coloré : FATAL, ABORT, PAUSE, WARN, SERVO, STOP, SYSTEM
- Base de données **embarquée** (SQLite) — fonctionne sans connexion réseau

## Captures

| Recherche | Détail |
|-----------|--------|
| Fuzzy search avec surbrillance des caractères matchés | Cause et remède complets |

## Stack

- Flutter 3.x / Dart 3.x
- `sqflite` — base SQLite embarquée
- Pas de backend, pas de réseau

## Structure

```
lib/
├── main.dart
├── models/
│   └── error_code.dart          # modèle de données
├── screens/
│   ├── search_screen.dart       # écran principal (recherche + filtres)
│   └── detail_screen.dart       # vue détail d'une alarme
└── services/
    ├── database_service.dart    # accès SQLite
    └── fuzzy_service.dart       # algorithme de recherche fuzzy + ranking
assets/
└── fanuc_errors.db              # base SQLite (11 290 entrées)
```

## Base de données

La base a été générée à partir du fichier `R-30iB Error Codes.xls` (Fanuc 2015) avec le script Python suivant :

```python
import xlrd, sqlite3
wb = xlrd.open_workbook('R-30iB Error Codes.xls')
sh = wb.sheet_by_index(0)
conn = sqlite3.connect('fanuc_errors.db')
conn.execute('''CREATE TABLE errors (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT NOT NULL, type TEXT,
    message TEXT, cause TEXT, remedy TEXT
)''')
conn.execute('CREATE INDEX idx_code ON errors(code)')
rows = [(sh.cell_value(i,0), sh.cell_value(i,1),
         sh.cell_value(i,2), sh.cell_value(i,3), sh.cell_value(i,4))
        for i in range(1, sh.nrows) if sh.cell_value(i,0)]
conn.executemany('INSERT INTO errors VALUES (NULL,?,?,?,?,?)', rows)
conn.commit()
```

## Build

```bash
# Prérequis : Flutter 3.x, Android SDK

flutter pub get
flutter run                          # debug sur téléphone branché
flutter build apk --release          # APK release
```

## Algorithme fuzzy

La recherche ne passe pas par SQL `LIKE` mais par un scorer en mémoire :

- Tous les codes sont chargés au démarrage (~11k entrées, <5 MB)
- Le tiret du code (`SRVO-001`) est ignoré à la frappe
- Score : **+15×n** par caractère consécutif, **+10** en début de mot, **+2** sinon
- Résultats triés par score décroissant, limités à 200
- Debounce 120 ms pour éviter le recalcul à chaque frappe
