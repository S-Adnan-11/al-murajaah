# Contributing

We welcome developers interested in Qur’an revision tools. Participation is open to everyone.

We are concentrating on maintaining the Android release. Focused fixes, documentation and testing are useful contributions. Before starting a substantial change, open an issue in the [feedback tracker](https://github.com/S-Adnan-11/al-murajaah-feedback/issues) so we can agree on the approach. Pull requests belong in [this source repository](https://github.com/S-Adnan-11/al-murajaah).

## Start here

1. Follow [Build and run](README.md#build-and-run) for the pinned Flutter, Java and Android tools. Debug builds and the unit/widget suite need no production keys, service credentials or private audio.
2. Work on a branch. Keep `pubspec.lock` and avoid unrelated dependency upgrades. Use an emulator or a test device/profile: a development signing key generally cannot update the distributed app.
3. Choose a small change and find its source and tests using the map below. Run a related test before editing, then check your change.

## How the app fits together

| Area | Start reading | Related tests |
| --- | --- | --- |
| Startup and shared dependencies | [main.dart](lib/main.dart), [foundation_app.dart](lib/app/foundation_app.dart), [product_dependencies.dart](lib/app/product_dependencies.dart) | `test/foundation_navigation_test.dart`, `test/product_shell_test.dart` |
| Playback and session intent | [prototype_handler.dart](lib/core/audio/prototype_handler.dart), [session_spec.dart](lib/core/audio/session_spec.dart), [product_controller.dart](lib/features/product/product_controller.dart) | `test/session_spec_test.dart`, `test/playback_intent_test.dart` |
| Catalogue and recording identity | [catalog_repository.dart](lib/features/catalog/catalog_repository.dart), `assets/catalog/` | `test/catalog_repository_test.dart` |
| Passages and local data | [foundation.drift](lib/core/database/foundation.drift), [foundation_repository.dart](lib/core/database/foundation_repository.dart), `lib/features/product/` | `test/passage_editor_test.dart`, `test/passage_library_test.dart`, `test/database/` |
| Downloads and offline files | `lib/features/downloads/`, `android/app/src/main/kotlin/` | `test/download_queue_test.dart` |
| Listening activity and backups | `lib/features/activity/`, `lib/features/backup/` | `test/listening_meter_test.dart`, `test/metadata_backup_test.dart` |
| Appearance and accessibility | `lib/core/theme/`, `lib/features/settings/` | `test/settings_semantics_test.dart`, `test/stage5_accessibility_test.dart` |
| Feedback | `lib/features/support/`, [Worker setup](services/feedback-worker/README.md) | `services/feedback-worker/test/relay.test.mjs` |

Playback has one authority: `PrototypeHandler`, backed by just_audio and audio_service. Screens can browse a different recording while the active session continues. Explicit Play changes the session; navigation and saving a passage must not do so. Keep that distinction when changing controls or routes.

Drift/SQLite stores passages, recording references, preferences and listening activity. Recording IDs identify particular bytes: changing a recording requires a new identity so saved passages keep their meaning. Downloads are usable offline only after size and SHA-256 verification.

Database changes need a migration and tests that preserve existing data. Keep historical schema fixtures and regenerate derived files with `dart run build_runner build`; don't edit generated Dart by hand. Backup compatibility also matters when changing stored data.

## Where help is welcome

- **Documentation:** try setup from a fresh clone and improve any unclear step, with the OS and tool versions you used.
- **Accessibility:** test TalkBack, large text and focus order on a named screen. Include concrete reproduction steps and a focused fix where possible.
- **Playback:** investigate device-specific interruptions, media controls or offline recovery. Include device/Android versions and steps that separate UI state from what you actually heard.
- **iOS investigation:** the runner is present, but builds and native integrations are unverified. A macOS/Xcode build report would help establish the remaining work; discuss implementation scope before starting.

These are areas to explore, not commitments to a feature or release date. Some older test filenames reflect development stages; use their assertions and the map above to find relevant coverage.

## Check your change

For a focused Dart check, for example:

```text
flutter test --no-pub test/session_spec_test.dart
```

For an app change, format the Dart source, run analysis and the unit/widget suite, and build a debug APK:

```text
dart format lib test integration_test test_driver
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

Use the existing two-space Dart format, lints and Kotlin conventions. Add tests for changed behaviour and persistence. Only regenerate database code when the change needs it.

For feedback relay changes, the protocol tests mock GitHub and need only Node.js 22 or newer:

```text
node --test services/feedback-worker/test/relay.test.mjs
```

Follow the [Worker README](services/feedback-worker/README.md) for locked runtime tools and workerd/SQLite checks. Never point automated tests at the production tracker.

Android CI runs on pushes and pull requests without private credentials. Native playback checks in `integration_test/` need the fixtures and bounds described by each check; some fixtures aren't distributed here. Use `--keep-app-running` with `flutter drive` to avoid its cleanup uninstall. Keep existing installations and user data intact. Playback-state assertions alone don't establish audible quality, battery life or iOS compatibility.

## Submit a pull request

Explain the problem, resulting behaviour and why the change helps. Link the issue or discussion, list checks actually run and their outcomes, and distinguish unexecuted checks from failures. Include sanitized screenshots for UI changes. Use focused commits with imperative messages such as `fix(audio): ...` or `docs: ...`.

Keep credentials, diagnostics, personal backups, audio and build artifacts out of Git and public reports. Use demonstration data in screenshots. Service deployment and release signing are separate from contributor checks; the app needs no GitHub token or Cloudflare secret to build.

Source contributions use this repository's [MIT licence](LICENSE). Preserve third-party notices. Before distributing a fork, follow the [asset permissions table](THIRD_PARTY_NOTICES.md#building-and-distributing-a-fork): retain font and metadata notices, and obtain permission for or replace restricted brand, portrait and audio assets.
