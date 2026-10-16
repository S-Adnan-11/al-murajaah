import 'package:flutter/material.dart';

import '../../core/theme/product_components.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Credits')),
    body: ListView(
      padding: AppSpace.page,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  image: true,
                  label: 'Goni Muhammad Bukar Zarami',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/credits/zarami.png',
                      width: 104,
                      height: 140,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(zaramiCredit),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.section),
        const Text(
          'Surah names and transliterations: Tanzil Quran Metadata v1.0, © 2008–2009 Tanzil.info, declared CC-BY (version unspecified). Names and aliases adapted for this app.\n\nArabic typography: Noto Sans Arabic, licensed under the SIL Open Font License. Full font and software licenses are available in Settings.',
        ),
      ],
    ),
  );
}

const zaramiCredit = r'''Goni Muhammad Bukar Zarami

One of the Imams of An-Nur Masjid, Abuja, and the primary reciter featured in Al-Murāja'ah with the Riwayah of Imam Hafs from Imam Aasim ibn Abi al-Najud رحمهم الله

Distribution and recording with Ijaazah
as in the Digital Qur'anic Archives

May Allah ﷻ preserve him and grant him abundant reward.''';
