import 'package:embrace_ai/state/auth_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthStore.participantCodeFromUri', () {
    test('normalizes a participant-bound QR redirect', () {
      final uri = Uri.parse(
        'https://embrace-ai-prototype-2026.web.app/'
        '?participant=EA-P8WN-P77A&access=qr',
      );

      expect(AuthStore.participantCodeFromUri(uri), 'EAP8WNP77A');
    });

    test('ignores missing or malformed participant values', () {
      expect(
        AuthStore.participantCodeFromUri(Uri.parse('https://example.test/')),
        isNull,
      );
      expect(
        AuthStore.participantCodeFromUri(
          Uri.parse('https://example.test/?participant=wrong'),
        ),
        isNull,
      );
    });
  });

  group('AuthStore.signInTokenFromUri', () {
    test('reads the one-time code from an app sign-in link', () {
      final uri = Uri.parse(
        'https://embrace-ai-prototype-2026.web.app/'
        '?signin=ef3497556f88d4280aa5d2384963f2a9a1641d41f6dd1f7fcf95b0be',
      );

      expect(
        AuthStore.signInTokenFromUri(uri),
        'ef3497556f88d4280aa5d2384963f2a9a1641d41f6dd1f7fcf95b0be',
      );
    });

    test('ignores missing or malformed codes', () {
      expect(
        AuthStore.signInTokenFromUri(Uri.parse('https://example.test/')),
        isNull,
      );
      expect(
        AuthStore.signInTokenFromUri(
          Uri.parse('https://example.test/?signin=<script>'),
        ),
        isNull,
      );
      expect(
        AuthStore.signInTokenFromUri(
          Uri.parse('https://example.test/?signin=abc123'),
        ),
        isNull,
      );
    });
  });
}
