import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/features/auth/widgets/otp_code_input.dart';

void main() {
  testWidgets('OTP input fits a narrow width and completes all six digits', (
    WidgetTester tester,
  ) async {
    String? completedCode;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: OtpCodeInput(onCompleted: (code) => completedCode = code),
            ),
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(6));
    expect(tester.takeException(), isNull);

    for (var index = 0; index < 6; index++) {
      await tester.enterText(fields.at(index), '${index + 1}');
    }
    await tester.pumpAndSettle();

    expect(completedCode, '123456');
    expect(tester.takeException(), isNull);
  });
}
