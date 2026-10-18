# Third-party notices and asset scope

The [MIT licence](LICENSE) covers this project's first-party source code. It does not replace dependency licences or grant rights to separately governed content.

| Material | Attribution and terms |
| --- | --- |
| Noto Sans Arabic | Google Fonts upstream provenance in [its README](assets/fonts/noto-sans-arabic/README.md); unmodified [SIL Open Font License 1.1](assets/fonts/noto-sans-arabic/OFL.txt) |
| Cairo | Google Fonts upstream provenance in [its README](assets/fonts/cairo/README.md); unmodified [SIL Open Font License 1.1](assets/fonts/cairo/OFL.txt) |
| Chapter names/transliterations | Tanzil Quran Metadata v1.0; source declares `cc-by` without a version. Attribution and extraction changes remain in [ATTRIBUTION.txt](assets/catalog/ATTRIBUTION.txt) |
| Flutter/Dart and packages | Their upstream licences remain applicable. Versions are recorded in `pubspec.lock`; Flutter’s in-app software licence viewer retains registered dependency/font notices |
| Gradle wrapper | Gradle project, Apache License 2.0; see the bundled [licence](android/gradle/wrapper/LICENSE.txt) |
| Recitations | The configured Zarami/Hafs collection and separately credited origin recordings. Audio is fetched from configured public delivery URLs; no recording bytes are committed or bundled in the APK |
| Brand artwork and credits portrait | Included for use in this project; no general downstream reuse grant is asserted here |

The app’s Credits and origin content supply recording attribution. Permission for recitations to be used by this app does not establish permission for forks or other parties to redistribute them. Obtain permission from the relevant rights holders before republishing recordings, portrait or brand assets. Do not overwrite audio under an existing immutable recording ID.

## Building and distributing a fork

The repository includes the assets needed to build this project locally. Availability in source does not grant permission to redistribute every asset in a fork. Use the following scope when preparing a distributable build:

| Asset | May a distributed fork retain it? | Required action |
| --- | --- | --- |
| First-party Dart, Kotlin, Swift and other source | Yes, under MIT | Retain the MIT copyright and permission notice |
| Noto Sans Arabic and Cairo font files | Yes, under SIL OFL 1.1 | Retain each bundled OFL/copyright notice; follow the OFL conditions for modifications and any reserved font names |
| Tanzil chapter names and transliterations | Under the upstream attribution terms | Retain the source attribution and extraction/change notice in assets/catalog/ATTRIBUTION.txt; upstream identifies cc-by without a version, so do not substitute an invented licence version |
| Gradle wrapper and third-party packages | Under their respective licences | Retain applicable licences/notices, including the wrapper LICENSE.txt and NOTICE.txt |
| assets/brand/, Android/iOS launcher and splash artwork, and branded screenshots | Requires permission before redistribution | Obtain permission from the relevant rights holder or replace/remove the artwork and screenshots before distributing a fork |
| assets/credits/zarami.png (reciter portrait) | Requires permission before redistribution | Obtain the portrait rights holder’s permission or replace/remove it before distributing a fork |
| Recitation audio, including files obtained through catalogue URLs | Requires permission before redistribution | Obtain the recording rights holders’ permission or use recordings you are permitted to distribute, with new recording identities for changed bytes |

The supplied brand/portrait files remain available as project inputs for local development; this statement grants no general artwork or recording licence. Audio is neither committed nor bundled. Catalogue URLs and hashes describe delivery and integrity, not downstream audio rights. Rehosting recordings or distributing a fork that uses this project's delivery service requires separate permission; do not treat a publicly accessible URL as that permission. Preserve font and metadata notices even when replacing restricted assets.
