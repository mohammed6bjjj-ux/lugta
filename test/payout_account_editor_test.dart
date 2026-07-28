import 'package:flutter/material.dart';
import 'package:flutter_app/data/models.dart';
import 'package:flutter_app/features/wallet/payout_accounts_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'seller submits SuperQi with the registered holder name and any numeric identifier',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? capturedProvider;
      String? holderName;
      String? identifier;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PayoutAccountEditorSheet(
              onSave:
                  ({
                    required provider,
                    required accountHolderName,
                    required accountIdentifier,
                    required makeDefault,
                  }) async {
                    capturedProvider = provider;
                    holderName = accountHolderName;
                    identifier = accountIdentifier;
                    return PayoutAccount(
                      id: 'new-account',
                      provider: provider,
                      accountHolderName: accountHolderName,
                      accountIdentifier: accountIdentifier,
                      identifierLast4: accountIdentifier,
                      isVerified: false,
                      isDefault: makeDefault,
                    );
                  },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('payout_provider_superqi')));
      await tester.enterText(
        find.byKey(const ValueKey('payout_account_holder_field')),
        'أحمد كريم',
      );
      await tester.enterText(
        find.byKey(const ValueKey('payout_account_identifier_field')),
        '12345',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('save_payout_account_button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('save_payout_account_button')),
      );
      await tester.pumpAndSettle();

      expect(capturedProvider, 'superqi');
      expect(holderName, 'أحمد كريم');
      expect(identifier, '12345');
    },
  );
}
