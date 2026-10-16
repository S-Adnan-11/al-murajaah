import 'package:al_murajaah/core/theme/app_theme.dart';
import 'package:al_murajaah/features/support/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'About last action clears system navigation at $scale in $brightness',
        (tester) async {
          tester.view.physicalSize = const Size(480, 800);
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(bottom: 48);
          tester.view.viewPadding = const FakeViewPadding(bottom: 48);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPadding);
          addTearDown(tester.view.resetViewPadding);
          const channel = MethodChannel('dev.almurajaah/support');
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(channel, (call) async => '1.0.0');
          addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
          var privacyOpened = false;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.forBrightness(brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: AboutScreen(
                developer: () {},
                credits: () {},
                licenses: () {},
                feedback: () {},
                privacy: () => privacyOpened = true,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
          for (var attempt = 0; attempt < 8; attempt++) {
            scroll.position.jumpTo(scroll.position.maxScrollExtent);
            await tester.pumpAndSettle();
            if ((scroll.position.pixels - scroll.position.maxScrollExtent)
                    .abs() <
                0.5) {
              break;
            }
          }
          final action = find.widgetWithText(ListTile, 'Privacy & help');
          expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(752));
          await tester.tap(find.text('Privacy & help'));
          expect(privacyOpened, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
