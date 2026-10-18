# Android release checklist

We distribute a universal APK through [GitHub Releases](https://github.com/S-Adnan-11/al-murajaah/releases). Debug CI artifacts are for development. Production signing material stays outside source control. Run build and verification commands from the repository root unless a step specifies another directory.

1. **Choose the version.** Update `pubspec.yaml` with the release version and an explicit build number higher than every distributed build. Check GitHub Releases and any test distribution before choosing it; the current public release is `1.0.1+36`. Keep the existing application ID, `dev.almurajaah.al_murajaah.diagnostic`.
2. **Check the source.** Use the pinned toolchain in the README and `flutter pub get --enforce-lockfile`. Run analysis, unit/widget/migration tests and a debug build. For relay changes, run its mocked and runtime checks separately. Inspect the exact release diff for credentials, personal data and unintended files. Keep test reports and signing material private.
3. **Build with the production signer.** Configure `android/production/key.properties` locally and use the existing production key. The build checks its certificate fingerprint and refuses a substitute. Supply the maintained public HTTPS feedback endpoint; the app receives no service credentials. Replace `VERSION`, `BUILD` and `FEEDBACK_URL` below with actual values:

   ```text
   flutter build apk --release --no-pub --build-name VERSION --build-number BUILD --dart-define=FEEDBACK_ENDPOINT=FEEDBACK_URL
   ```

4. **Inspect the APK.** Use Android Build Tools `apksigner verify --verbose --print-certs` on `build/app/outputs/flutter-apk/app-release.apk`. Compare the certificate SHA-256 with `acac6c5bc482ea7c9246fd233fc59efe707b65779c40b17f9d663b3937f0737d`. Use `aapt2 dump badging` to verify package ID, version name/code, minimum SDK and ABIs, and check that `application-debuggable` is absent. Test an in-place update over the preceding production build on a test device, retaining passages, preferences and activity. Exercise playback, offline downloads and backup import/export. Check feedback manually only when a real public test submission is intended.
5. **Prepare the downloads.** Copy the verified APK into a private release directory and give it the final download filename. Generate a `.sha256` companion for those final bytes. For example, with the APK named `Al-Murajaah.apk` in the current directory:

   ```powershell
   $apkName = 'Al-Murajaah.apk'
   $digest = (Get-FileHash -LiteralPath $apkName -Algorithm SHA256).Hash.ToLowerInvariant()
   Set-Content -LiteralPath ($apkName + '.sha256') -Value ($digest + '  ' + $apkName) -Encoding ascii
   ```

6. **Prepare and publish the release.** Review the tag/commit, version, concise release notes, APK and checksum together. Describe current limitations and any migration steps accurately. Publish the release with both files, then download them and compare the checksum again. Update the README's current version and installation details, and check that the About website and README Download link resolve to the release.

Release signing and Worker deployment are independent. An APK update does not require redeploying the relay; a relay update must retain its Durable Object namespace and migration history. Never replace a release APK silently with different bytes or use a different signer for an ordinary update.
