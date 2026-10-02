# Al-Muraja'ah

Stage 1 Flutter audio diagnostic for Zarami/Hafs passage playback. Android is the active target; iOS is unverified. This is not a signed production release.

- [Product plan](docs/V1_PLAN.md)
- [Setup and AWS emulator](docs/SETUP.md)
- [Diagnostic usage and native tests](docs/STAGE1.md)
- [Actual test results](TEST_REPORT.md)

Run `flutter pub get`, `flutter analyze`, `flutter test` and `flutter run -d DEVICE_ID` with the locked Flutter toolchain. Physical-device acceptance remains pending. Audio files and signing secrets are excluded from Git. Code licensing and final release identity remain owner decisions.
