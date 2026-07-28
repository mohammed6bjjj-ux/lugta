import 'package:flutter_app/core/external_actions.dart';
import 'package:flutter_app/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('security validation', () {
    test('password policy matches the eight-character backend minimum', () {
      expect(validatePassword('1234567'), isNotNull);
      expect(validatePassword('12345678'), isNull);
      expect(validatePassword(' 12345678'), isNotNull);
      expect(validatePassword('12345678 '), isNotNull);
      expect(validatePassword('1234 5678'), isNull);
    });

    test(
      'login accepts existing shorter passwords but rejects empty input',
      () {
        expect(validateLoginPassword(''), isNotNull);
        expect(validateLoginPassword('      '), isNotNull);
        expect(validateLoginPassword('123456'), isNull);
        expect(validateLoginPassword('1234567'), isNull);
        expect(validateLoginPassword(' 123456'), isNotNull);
        expect(validateLoginPassword('123456 '), isNotNull);
        expect(validateLoginPassword('123 456'), isNull);
      },
    );

    test('Instagram links are normalized and unsafe schemes are rejected', () {
      expect(
        instagramProfileUri('@safe_store').toString(),
        'https://instagram.com/safe_store',
      );
      expect(
        instagramProfileUri('instagram.com/safe_store').toString(),
        'https://instagram.com/safe_store',
      );
      expect(
        instagramProfileUri('instagram.com/safe_store/').toString(),
        'https://instagram.com/safe_store',
      );
      expect(
        instagramProfileUri('http://www.instagram.com/safe_store').toString(),
        'https://instagram.com/safe_store',
      );
      expect(
        instagramProfileHandle('https://m.instagram.com/safe.store/'),
        'safe.store',
      );
      expect(
        normalizeInstagramProfile('safe_store'),
        'https://instagram.com/safe_store',
      );
      expect(instagramProfileUri('javascript:alert(1)'), isNull);
      expect(instagramProfileUri('https://example.com/safe_store'), isNull);
      expect(instagramProfileUri('https://instagram.com/safe/other'), isNull);
      expect(
        instagramProfileUri('https://instagram.com/accounts/login'),
        isNull,
      );
      expect(instagramProfileUri('safe..store'), isNull);
      expect(instagramProfileUri('../unsafe'), isNull);
    });
  });
}
