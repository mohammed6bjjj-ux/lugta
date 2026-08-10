import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/app/theme.dart';
import 'package:flutter_app/data/session.dart';
import 'package:flutter_app/features/profile/edit_profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('profile editor previews a picked avatar and allows removal', (
    tester,
  ) async {
    final originalSeller = session.seller;
    addTearDown(() => session.seller = originalSeller);
    session.seller = originalSeller.copyWith(avatarPath: '', avatarUrl: '');
    final pngBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: EditProfileScreen(
          pickImage: () async => XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: 'avatar.png',
          ),
          recoverLostData: () async => LostDataResponse.empty(),
        ),
      ),
    );
    await tester.pump();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    await tester.tap(find.text('اختيار صورة'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('إزالة الصورة'), findsOneWidget);

    await tester.tap(find.text('إزالة الصورة'));
    await tester.pump();

    expect(find.text('إزالة الصورة'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
