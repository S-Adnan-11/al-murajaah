import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/product_components.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({
    super.key,
    required this.developer,
    required this.credits,
    required this.licenses,
    required this.feedback,
    required this.privacy,
  });
  final VoidCallback developer, credits, licenses, feedback, privacy;
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final _version = const MethodChannel('dev.almurajaah/support')
      .invokeMethod<String>('publicVersion');
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About App')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: AppSpace.page,
        children: [
          const Center(child: BrandMark(size: 136)),
          const Center(child: BrandWordmark()),
          const SizedBox(height: 12),
          Text(
            "Al-Murāja'ah",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          FutureBuilder<String?>(
            future: _version,
            builder: (_, version) => Text(
              version.hasData
                  ? 'Version ${version.data}'
                  : version.hasError
                  ? 'Version unavailable'
                  : '',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'A companion for Qur’an revision: listen, repeat a passage, save it and return to it.',
          ),
          const SizedBox(height: 16),
          const Text(
            '114 surahs · Verified offline downloads · Saved passages · Finite and continuous repeats · Background listening · Activity and metadata backup',
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.record_voice_over_outlined),
                  title: const Text('Credits'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: widget.credits,
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Font and software licenses'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: widget.licenses,
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy & help'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: widget.privacy,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
