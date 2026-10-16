# Contributing

Developers interested in Qur’an revision tools, including Muslim developers, are welcome. Participation is open to everyone. Please keep discussions respectful and practical.

V1 is accepted and product development is frozen. Discuss a proposed fix, maintenance change or future feature before starting substantial work. User reports and suggestions belong in the [feedback tracker](https://github.com/S-Adnan-11/al-murajaah-feedback/issues); source changes and pull requests belong in [this repository](https://github.com/S-Adnan-11/al-murajaah).

## Make a focused change

1. Follow the pinned prerequisites and setup in the [README](README.md). Keep `pubspec.lock`; avoid unrelated dependency upgrades.
2. Work on a branch and use a disposable emulator/test profile. Debug builds need no distribution key. Never uninstall or clear an existing owner installation to make a check pass.
3. Preserve one `PrototypeHandler`, independent browsing, explicit Play session changes, immutable recording IDs, saved ranges, database compatibility and backup formats. Keep the current story and approved branding intact. Future product work needs a deliberate V2 decision.
4. Use formatter-controlled two-space Dart indentation and existing Flutter/Kotlin conventions. For a Drift schema change, provide an additive migration, preserve historical fixtures, regenerate derived files and cover data preservation.
5. Run relevant checks and explain the results in your PR:

```text
dart format lib test integration_test test_driver
dart run build_runner build
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
node --test services/feedback-worker/test/relay.test.mjs
```

Only regenerate database code when relevant. Add meaningful tests for changed behavior and persistence. Native checks need their stated fixtures and bounded runs; use `--keep-app-running` with `flutter drive`. Distinguish an actual failure from a check you did not execute. An emulator transport pass does not establish acoustic quality, phone battery life or iOS compatibility.

## Submit a pull request

Explain the problem, resulting behavior, rationale and validation. Link the relevant issue and include sanitized screenshots for UI changes. Keep commits coherent with imperative messages such as `fix(audio): ...` or `docs: ...`. Do not include co-author trailers.

Keep private plans, evidence, diagnostics, audio, backups, APKs, local SDK paths and credentials out of Git. Do not weaken ignore rules or include personal saves in screenshots. Worker changes must never embed a GitHub token in source or Flutter configuration; local tests mock upstream requests. Deployment and production state changes require separate maintainer coordination.

Your first-party source contribution is provided under this repository’s [MIT licence](LICENSE). Preserve third-party notices. Before distributing a fork, follow the [asset permissions table](THIRD_PARTY_NOTICES.md#building-and-distributing-a-fork): retain font and metadata notices, and obtain permission for or replace restricted brand/portrait/audio assets.
