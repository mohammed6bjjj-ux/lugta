import 'package:flutter/material.dart';
import 'package:flutter_app/features/wallet/payout_account_rules.dart';
import 'package:flutter_app/features/wallet/wallet_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SuperQi accepts any non-empty numeric account number', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    const fieldKey = ValueKey('superqi_account_field');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              key: fieldKey,
              controller: controller,
              inputFormatters: payoutAccountInputFormatters('superqi'),
              validator: (value) => validatePayoutAccountIdentifier(
                provider: 'superqi',
                value: value ?? '',
              ),
            ),
          ),
        ),
      ),
    );

    const longNumber = '1234567890123456789012345';
    await tester.enterText(find.byKey(fieldKey), longNumber);
    await tester.pump();
    expect(controller.text, longNumber);
    expect(formKey.currentState?.validate(), isTrue);

    await tester.enterText(find.byKey(fieldKey), '');
    await tester.pump();
    expect(formKey.currentState?.validate(), isFalse);
    await tester.pump();
    expect(find.text(WalletStrings.superQiNumberRequired), findsOneWidget);

    controller.dispose();
  });
}
