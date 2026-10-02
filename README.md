# Al-Muraja'ah

Flutter Android audio prototype for Zarami/Hafs passage revision. The implementation includes one native playback handler, bounded repetition, verified audio downloads, appearance modes, Arabic typography, SQL preferences, routes and database migration tests. This is a development build, not a production release. iOS is unverified.

## Development

Use Flutter 3.47.5 at commit `6a19cca56475dbfba1478ee68d7bd0c2ef891da1` (Dart 3.13.4), JDK 21 and compatible Android SDK tooling.

```text
flutter pub get --enforce-lockfile
dart run build_runner build
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
flutter run -d DEVICE_ID
```

Replace DEVICE_ID with an observed Android target. Android CI checks locked dependencies, generated-code consistency, analysis, tests and a debug build. Its debug artifact is build evidence, not a signed release or an update for a differently signed installation.

Only the three verified public sample recordings are configured; the production catalog and background download queue remain unfinished. Existing diagnostic storage remains separate from the SQL foundation.

Private plans, setup notes, test reports, recordings, APKs, diagnostics, local SDK paths and signing material are excluded from Git. Code licensing, final application identity and release signing remain owner decisions. The bundled Arabic font retains its separate [OFL license and provenance](assets/fonts/noto-sans-arabic/README.md).
