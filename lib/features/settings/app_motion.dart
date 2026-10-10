import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';

/// Only preference changes rebuild this boundary; activity and download writes
/// have no subscription here. System reduced motion always wins.
class AppMotion extends StatefulWidget {
  const AppMotion({super.key, required this.db, required this.child});
  final AppDatabase db;
  final Widget child;
  @override
  State<AppMotion> createState() => _AppMotionState();
}

class _AppMotionState extends State<AppMotion> {
  late final _motion = widget.db
      .select(widget.db.appSettings)
      .watchSingle()
      .map((settings) => settings.reducedMotion == 1)
      .distinct();
  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: _motion,
    builder: (context, snapshot) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: media.disableAnimations || (snapshot.data ?? true),
        ),
        child: widget.child,
      );
    },
  );
}
