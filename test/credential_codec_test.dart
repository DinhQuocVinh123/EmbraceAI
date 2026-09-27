import 'package:embrace_ai/services/credential_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('participant credentials normalize their display formatting', () {
    expect(CredentialCodec.normalizeCode('ea-23ab-89xy'), 'EA23AB89XY');
    expect(
      CredentialCodec.normalizeAccessKey('2345-6789-abcd-efgh'),
      '23456789ABCDEFGH',
    );
  });

  test('participant email is deterministic and contains no real identity', () {
    expect(
      CredentialCodec.participantEmail('EA-23AB-89XY'),
      'ea23ab89xy@participant.embrace.invalid',
    );
  });
}
