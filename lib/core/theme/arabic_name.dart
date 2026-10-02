import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Local font assets: opening the app never requests a font from the network.
abstract final class ArabicTypography {
  static const family = 'NotoSansArabic';
  static const fontAsset =
      'assets/fonts/noto-sans-arabic/NotoSansArabic-Variable.ttf';
  static const licenseAsset = 'assets/fonts/noto-sans-arabic/OFL.txt';
  static bool _licenseRegistered = false;

  static void registerLicense() {
    if (_licenseRegistered) return;
    _licenseRegistered = true;
    // Read lazily on the licenses page, outside the startup work.
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks([
        'Noto Sans Arabic',
      ], await rootBundle.loadString(licenseAsset));
    });
  }
}

/// A name has its own Arabic direction and language, within the English UI.
/// Do not concatenate it with a number or transliteration in a single Text.
class ArabicName extends StatelessWidget {
  const ArabicName(this.name, {super.key});
  final String name;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    textDirection: TextDirection.rtl,
    localeForSubtree: const Locale('ar'),
    child: Text(
      name,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      locale: const Locale('ar'),
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontFamily: ArabicTypography.family,
        fontWeight: FontWeight.w400,
        height: 1.8,
      ),
    ),
  );
}
