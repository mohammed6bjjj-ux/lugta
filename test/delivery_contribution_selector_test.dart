import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/core/widgets/delivery_contribution_selector.dart';
import 'package:flutter_app/data/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    appSettings.language = AppLanguage.ar;
    appSettings.darkMode = false;
  });

  testWidgets('presets choose customer, split, or full seller contribution', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      _TestHost(
        child: StatefulBuilder(
          builder: (context, setState) => DeliveryContributionSelector(
            deliveryFee: 5000,
            grossProfit: 8000,
            value: selected,
            onChanged: (value) => setState(() => selected = value),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('delivery_contribution_split')));
    await tester.pump();
    expect(selected, 2500);

    await tester.tap(
      find.byKey(const ValueKey('delivery_contribution_seller')),
    );
    await tester.pump();
    expect(selected, 5000);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profit caps contribution and compact Arabic layout stays usable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var selected = 0;
      await tester.pumpWidget(
        _TestHost(
          textScale: 2,
          child: StatefulBuilder(
            builder: (context, setState) => DeliveryContributionSelector(
              deliveryFee: 5000,
              grossProfit: 3200,
              value: selected,
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('delivery_contribution_slider')),
      );
      expect(slider.max, 3000);
      expect(
        tester
            .widget<InkWell>(
              find.descendant(
                of: find.byKey(const ValueKey('delivery_contribution_seller')),
                matching: find.byType(InkWell),
              ),
            )
            .onTap,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a free promotion never offers a seller deduction', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestHost(
        child: DeliveryContributionSelector(
          deliveryFee: 0,
          grossProfit: 8000,
          value: 0,
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('delivery_contribution_free_offer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('delivery_contribution_slider')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

class _TestHost extends StatelessWidget {
  const _TestHost({required this.child, this.textScale = 1});

  final Widget child;
  final double textScale;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: child,
              ),
            ),
          );
        },
      ),
    ),
  );
}
