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
}
