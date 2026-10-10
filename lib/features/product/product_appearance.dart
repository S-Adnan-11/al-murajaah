import 'package:flutter/material.dart';

import '../../core/theme/themed_app.dart';
import '../../core/theme/product_components.dart';

/// Normal appearance settings. The Stage 2 gallery remains in the legacy
/// diagnostic route/tests rather than becoming a normal product workflow.
class ProductAppearance extends StatelessWidget {
  const ProductAppearance({super.key});
  @override
  Widget build(BuildContext context) {
    final mode = AppearanceScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppSpace.page,
          children: [
            Text(
              'Make it comfortable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a light or dark appearance, or follow your phone.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in ThemeMode.values)
                  ChoiceChip(
                    label: Text(switch (choice) {
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                      ThemeMode.system => 'System',
                    }),
                    selected: mode.value == choice,
                    onSelected: mode.saving ? null : (_) => mode.select(choice),
                  ),
              ],
            ),
            if (mode.saving)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Saving appearance…'),
              ),
            if (mode.saveError != null)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Your appearance could not be saved. Try again.'),
              ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Font and software licenses'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Al-Muraja’ah',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
