abstract final class CredentialCodec {
  static String normalizeCode(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  static String normalizeAccessKey(String value) =>
      value.trim().toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  static String participantEmail(String code) =>
      '${normalizeCode(code).toLowerCase()}@participant.embrace.invalid';
}
