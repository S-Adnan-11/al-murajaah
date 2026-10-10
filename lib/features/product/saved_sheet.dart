import 'package:flutter/material.dart';

import '../../core/theme/product_components.dart';

import 'product_controller.dart';
import 'passage_library.dart';
import '../catalog/catalog.dart';

class SavedSheet extends StatefulWidget {
  const SavedSheet({
    super.key,
    required this.controller,
    required this.open,
    this.combinedStarred = false,
    this.openSurah,
  });
  final ProductController controller;
  final void Function(LibraryPassage, bool play, bool edit) open;
  final void Function(CatalogRecording, bool play)? openSurah;
  final bool combinedStarred;
  @override
  State<SavedSheet> createState() => _SavedSheetState();
}

class _SavedSheetState extends State<SavedSheet> {
  String query = '', sort = 'Recent';
  bool starred = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  Future<void> _menu(LibraryPassage p, String action) async {
    final c = widget.controller;
    try {
      if (action == 'Edit') {
        widget.open(p, false, true);
        return;
      }
      if (action == 'Star') {
        await c.favoritePassage(p);
        return;
      }
      if (action == 'Delete') {
        final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete ${p.title}?'),
            content: const Text(
              'Only this saved passage is removed. Audio and other saves remain.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (yes == true) {
          await c.library.delete(p.id);
          await c.refreshSaved();
        }
        return;
      }
      final name = TextEditingController(
        text: action == 'Duplicate' ? '${p.title} copy' : p.title,
      );
      final value = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('$action passage'),
          content: TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Passage name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty) {
                  FocusScope.of(ctx).unfocus();
                  Navigator.pop(ctx, name.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
      // The route animation may still hold the field; dispose after completion.
      if (value != null) {
        if (action == 'Rename') {
          await c.renamePassage(p, value);
        } else {
          await c.library.save(
            value,
            p.spec,
            note: p.row.note,
            speed: p.row.speed,
          );
          await c.refreshSaved();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This change could not be saved. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final surahs = widget.combinedStarred
        ? c.dependencies.catalog
              .search(query)
              .where((r) => c.favorites.contains('${r.number}'))
              .toList()
        : <CatalogRecording>[];
    final rows = c.saved
        .where(
          (p) =>
              (p.title.toLowerCase().contains(query.toLowerCase()) ||
                  p.recordingName.toLowerCase().contains(
                    query.toLowerCase(),
                  )) &&
              (!(starred || widget.combinedStarred) ||
                  c.passageFavorites.contains(p.id)),
        )
        .toList();
    rows.sort(
      (a, b) => sort == 'Name'
          ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
          : b.row.updatedUtcMs.compareTo(a.row.updatedUtcMs),
    );
    return CustomScrollView(
      key: PageStorageKey('saved-${widget.combinedStarred}'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    labelText: widget.combinedStarred
                        ? 'Search starred items'
                        : 'Search saved passages',
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!widget.combinedStarred)
                      FilterChip(
                        label: const Text('All passages'),
                        selected: !starred,
                        onSelected: (_) => setState(() => starred = false),
                      ),
                    if (!widget.combinedStarred)
                      FilterChip(
                        label: const Text('Starred'),
                        selected: starred,
                        onSelected: (_) => setState(() => starred = true),
                      ),
                    PopupMenuButton<String>(
                      tooltip: 'Sort passages',
                      initialValue: sort,
                      itemBuilder: (_) => [
                        for (final s in ['Recent', 'Name'])
                          CheckedPopupMenuItem(
                            value: s,
                            checked: sort == s,
                            child: Text(s),
                          ),
                      ],
                      onSelected: (v) => setState(() => sort = v),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(sort),
                            const Icon(Icons.expand_more_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.combinedStarred
                      ? '${surahs.length} surahs · ${rows.length} passages'
                      : '${rows.length} saved ${rows.length == 1 ? 'passage' : 'passages'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        if (rows.isEmpty && surahs.isEmpty)
          SliverToBoxAdapter(
            child: EmptyCollection(
              icon: widget.combinedStarred || starred
                  ? Icons.star_border_rounded
                  : Icons.bookmark_border_rounded,
              title: query.isNotEmpty
                  ? 'No matches'
                  : widget.combinedStarred || starred
                  ? 'No starred items yet'
                  : 'Save a passage to return to',
              message: query.isNotEmpty
                  ? 'Try another name or change the filter.'
                  : widget.combinedStarred
                  ? 'Star a surah or a saved passage to find it here.'
                  : starred
                  ? 'Star a saved passage to find it here.'
                  : 'Open a surah and choose Set passage to save an A–B range.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList.separated(
              itemCount: surahs.length + rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.gap),
              itemBuilder: (context, index) {
                if (index < surahs.length) {
                  final r = surahs[index];
                  return CollectionTile(
                    title: r.name,
                    leading: SurahNumberBadge(r.number),
                    details: 'Surah · Full surah',
                    onOpen: () => widget.openSurah!(r, false),
                    actions: [
                      IconButton(
                        tooltip: 'Play ${r.name}',
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: () => widget.openSurah!(r, true),
                      ),
                      IconButton(
                        tooltip: 'Unstar ${r.name}',
                        icon: const Icon(Icons.star_rounded),
                        onPressed: () => c.favorite(r),
                      ),
                    ],
                  );
                }
                final p = rows[index - surahs.length];
                return CollectionTile(
                  title: p.title,
                  starred: c.passageFavorites.contains(p.id),
                  details:
                      '${widget.combinedStarred ? 'Passage · ' : ''}${p.recordingName}\n${playbackTime(p.row.startMs)} – ${playbackTime(p.row.endMs)}',
                  warning: p.review
                      ? 'Recording replaced — review timestamps'
                      : null,
                  onOpen: () => widget.open(p, false, false),
                  actions: [
                    IconButton(
                      tooltip: 'Play ${p.title}',
                      onPressed: () => widget.open(p, true, false),
                      icon: const Icon(Icons.play_arrow_rounded),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Manage ${p.title}',
                      onSelected: (v) => _menu(p, v),
                      itemBuilder: (_) => [
                        for (final s in [
                          'Edit',
                          'Rename',
                          'Duplicate',
                          'Star',
                          'Delete',
                        ])
                          PopupMenuItem(
                            value: s,
                            child: Text(
                              s == 'Star' && c.passageFavorites.contains(p.id)
                                  ? 'Unstar'
                                  : s,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
