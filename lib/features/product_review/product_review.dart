import 'package:flutter/material.dart';

import '../../core/theme/arabic_name.dart';
import '../catalog/catalog.dart';

enum ReviewPage { home, surahs, player }

/// Isolated design review. This fixture is never a playback request/checkpoint.
/// No handler, repository, network request or persistence is owned by a screen.
class ProductReview extends StatefulWidget {
  const ProductReview({
    super.key,
    required this.catalog,
    this.initialPage = ReviewPage.home,
  });
  final Catalog catalog;
  final ReviewPage initialPage;
  @override
  State<ProductReview> createState() => _ProductReviewState();
}

class _ProductReviewState extends State<ProductReview> {
  late ReviewPage page = widget.initialPage;
  late int tab = widget.initialPage == ReviewPage.surahs ? 1 : 0;
  String query = '';
  late CatalogRecording recording = widget.catalog.chapter(9);

  void previewAction() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Design preview. Playback and saved data are unchanged.'),
    ),
  );

  void openPlayer() => setState(() {
    recording = widget.catalog.chapter(9);
    page = ReviewPage.player;
  });

  @override
  Widget build(BuildContext context) {
    final isPlayer = page == ReviewPage.player;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leading: isPlayer
            ? IconButton(
                tooltip: 'Close player',
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                onPressed: () => setState(
                  () => page = tab == 0 ? ReviewPage.home : ReviewPage.surahs,
                ),
              )
            : null,
        title: Text(
          isPlayer
              ? 'Now listening'
              : page == ReviewPage.home
              ? "Al-Muraja’ah"
              : 'Surahs',
        ),
        actions: [
          IconButton(
            tooltip: isPlayer ? 'Player options' : 'Settings',
            onPressed: previewAction,
            icon: Icon(isPlayer ? Icons.more_horiz : Icons.tune_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // This banner belongs to the review harness, not the proposed product.
          const _PreviewNotice(),
          Expanded(
            child: switch (page) {
              ReviewPage.home => _Home(
                onContinue: openPlayer,
                onBrowse: () => setState(() {
                  tab = 1;
                  page = ReviewPage.surahs;
                }),
                onFuture: previewAction,
              ),
              ReviewPage.surahs => _Surahs(
                catalog: widget.catalog,
                query: query,
                onQuery: (value) => setState(() => query = value),
                onSelect: (value) => setState(() {
                  recording = value;
                  page = ReviewPage.player;
                }),
              ),
              ReviewPage.player => _Player(
                recording: recording,
                onAction: previewAction,
              ),
            },
          ),
        ],
      ),
      bottomNavigationBar: isPlayer
          ? null
          : SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniPlayer(onOpen: openPlayer, onPlay: previewAction),
                  NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected: (value) {
                      if (value > 1) return;
                      setState(() {
                        tab = value;
                        page = value == 0 ? ReviewPage.home : ReviewPage.surahs;
                      });
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        selectedIcon: Icon(Icons.home_rounded),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.menu_book_outlined),
                        selectedIcon: Icon(Icons.menu_book_rounded),
                        label: 'Surahs',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bookmark_border_rounded),
                        label: 'Saved',
                        enabled: false,
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.bar_chart_rounded),
                        label: 'Activity',
                        enabled: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: Text(
      'DESIGN PREVIEW · illustrative paused session',
      style: Theme.of(context).textTheme.labelSmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
    ),
  );
}

class _Home extends StatelessWidget {
  const _Home({
    required this.onContinue,
    required this.onBrowse,
    required this.onFuture,
  });
  final VoidCallback onContinue, onBrowse, onFuture;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'A little revision,\nevery day.',
          style: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Return to your passage, at your own pace.',
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow('CONTINUE LISTENING'),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: ArabicName('التوبة'),
                ),
                Text(
                  'At-Tawbah',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zarami · Hafs',
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                const _Pill('Passage · 12:25–15:38'),
                const SizedBox(height: 12),
                Text('Today’s revision', style: text.titleMedium),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  value: 49 / 193,
                  minHeight: 4,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paused at 0:49 of 3:13 · Pass 2 of 5',
                  style: text.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Continue passage'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Your listening library',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Icon(Icons.menu_book_rounded, color: colors.primary),
            title: const Text('Browse all surahs'),
            subtitle: const Text('114 surahs · Zarami'),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: onBrowse,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onFuture,
          icon: const Icon(Icons.favorite_border_rounded),
          label: const Text('Starred'),
        ),
        const SizedBox(height: 24),
        Text(
          'Daily listening',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Your activity will appear here after listening.',
          style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Surahs extends StatelessWidget {
  const _Surahs({
    required this.catalog,
    required this.query,
    required this.onQuery,
    required this.onSelect,
  });
  final Catalog catalog;
  final String query;
  final ValueChanged<String> onQuery;
  final ValueChanged<CatalogRecording> onSelect;
  @override
  Widget build(BuildContext context) {
    final rows = catalog.search(query);
    final colors = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: onQuery,
                  decoration: const InputDecoration(
                    labelText: 'Search surahs',
                    hintText: 'Name or number',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Zarami · Hafs · ${rows.length} surahs',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (rows.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Text('No matching surahs. Try a name or number.'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverList.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _SurahRow(recording: rows[index], onSelect: onSelect),
            ),
          ),
      ],
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.recording, required this.onSelect});
  final CatalogRecording recording;
  final ValueChanged<CatalogRecording> onSelect;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: recording.available ? () => onSelect(recording) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${recording.number}',
                  style: text.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ArabicName(recording.arabicName),
                    ),
                    Text(
                      recording.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recording.available
                          ? '${playbackTime(recording.durationMs!)} · Not downloaded'
                          : 'Recording under review',
                      style: text.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                recording.available
                    ? Icons.chevron_right_rounded
                    : Icons.info_outline_rounded,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Player extends StatelessWidget {
  const _Player({required this.recording, required this.onAction});
  final CatalogRecording recording;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final passage = recording.number == 9;
    final duration = passage ? 193000 : recording.durationMs!;
    final position = passage ? 49000 : 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primaryContainer, colors.surface],
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.graphic_eq_rounded, size: 40, color: colors.primary),
              const SizedBox(height: 10),
              ArabicName(recording.arabicName),
              const SizedBox(height: 8),
              Text(
                recording.name,
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Zarami · Hafs',
                style: text.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Center(child: _Pill(passage ? 'Passage · 12:25–15:38' : 'Full surah')),
        const SizedBox(height: 12),
        if (passage)
          Text(
            'Today’s revision',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
        const SizedBox(height: 16),
        Text(
          'Paused',
          textAlign: TextAlign.center,
          style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant),
        ),
        Slider(
          value: position.toDouble(),
          max: duration.toDouble(),
          onChanged: (_) => onAction(),
          semanticFormatterCallback: (value) =>
              '${playbackTime(value.round())} into ${passage ? 'passage' : 'surah'}',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(playbackTime(position), style: text.bodyMedium),
            Text(
              '−${playbackTime(duration - position)}',
              style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (passage)
          Text(
            'Source position 13:14 · Passage length 3 min',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Back 10 seconds',
              iconSize: 32,
              onPressed: onAction,
              icon: const Icon(Icons.replay_10_rounded),
            ),
            SizedBox(
              width: 76,
              height: 76,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                onPressed: onAction,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 42,
                  semanticLabel: 'Resume playback',
                ),
              ),
            ),
            IconButton(
              tooltip: 'Forward 10 seconds',
              iconSize: 32,
              onPressed: onAction,
              icon: const Icon(Icons.forward_10_rounded),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Eyebrow('PLAY COUNT'),
                    const SizedBox(height: 4),
                    Text(
                      passage ? 'Pass 2 of 5' : 'Play once',
                      style: text.titleMedium,
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.repeat_rounded, size: 20),
                  label: const Text('Change'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.content_cut_rounded),
              label: const Text('Create passage'),
            ),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Download'),
            ),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.favorite_border_rounded),
              label: const Text('Star'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({required this.onOpen, required this.onPlay});
  final VoidCallback onOpen, onPlay;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
        child: Row(
          children: [
            Icon(
              Icons.graphic_eq_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'At-Tawbah · Today’s revision',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Paused · Pass 2 of 5',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Resume passage',
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
    ),
  );
}
