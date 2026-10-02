import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'arabic_name.dart';
import 'themed_app.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final palette = theme.brightness == Brightness.dark
        ? AppPalette.dark
        : AppPalette.light;
    final mode = AppearanceScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('appearance-content'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'A calm space to revise',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Turquoise, deep navy and a little warmth. Choose how Al-Muraja’ah looks on your phone.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final choice in ThemeMode.values)
                          ChoiceChip(
                            label: Text(switch (choice) {
                              ThemeMode.system => 'System',
                              ThemeMode.light => 'Light',
                              ThemeMode.dark => 'Dark',
                            }),
                            selected: mode.value == choice,
                            onSelected: mode.saving
                                ? null
                                : (_) => mode.select(choice),
                          ),
                      ],
                    ),
                    if (mode.saving)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Saving appearance…'),
                      ),
                    if (mode.saveError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Appearance could not be saved. Your previous choice is retained. Try again.',
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Card(
                      color: palette.atmosphere,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_stories_rounded,
                              size: 32,
                              color: colors.primary,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.secondary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Al-Muraja'ah",
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Listen. Repeat. Return.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            const _StatusLabel(
                              label: 'Ready to revise',
                              icon: Icons.check_circle_outline,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Readable by design',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your next revision',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Clear titles and comfortable reading, in either theme.',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Supporting details stay quieter, while remaining readable.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const Divider(height: 32),
                            Text(
                              'These are appearance examples. Playback controls remain on the audio screen.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Arabic names', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Surah name typography preview',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            for (final example in const [
                              ('الفاتحة', 'Al-Fatihah'),
                              ('التوبة', 'At-Tawbah'),
                              ('الهمزة', 'Al-Humazah'),
                            ]) ...[
                              ArabicName(example.$1),
                              Text(
                                example.$2,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextButton(
                              onPressed: () => showLicensePage(
                                context: context,
                                applicationName: "Al-Muraja'ah",
                              ),
                              child: const Text('Font and software licenses'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Controls', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to audio'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const OutlinedButton(
                          onPressed: null,
                          child: Text('Unavailable'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Preview passage name',
                        hintText: 'A name for your revision',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _StatusLabel(
                          label: 'Downloaded',
                          icon: Icons.download_done,
                        ),
                        _StatusLabel(label: 'Offline', icon: Icons.wifi_off),
                        _StatusLabel(
                          label: 'Buffering',
                          icon: Icons.hourglass_top,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colors.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Example error: Download could not finish. Your saved passage is still available.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Review text size, contrast and touch targets. This preview uses a static background; no aurora animation is running.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: TextStyle(color: colors.onSurface)),
          ),
        ],
      ),
    );
  }
}
