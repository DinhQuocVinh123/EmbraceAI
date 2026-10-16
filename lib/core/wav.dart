import 'dart:math' as math;
import 'dart:typed_data';

/// Đóng mẫu âm thanh (-1..1, một kênh) thành file WAV PCM 16-bit, đúng dạng
/// whisper.cpp đọc thẳng được mà máy GPU không cần cài ffmpeg.
Uint8List encodeWav(Float32List samples, int sampleRate) {
  const headerBytes = 44;
  final dataBytes = samples.length * 2;
  final bytes = ByteData(headerBytes + dataBytes);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataBytes, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little); // cỡ khối fmt
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, 1, Endian.little); // một kênh
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little); // byte mỗi giây
  bytes.setUint16(32, 2, Endian.little); // byte mỗi mẫu
  bytes.setUint16(34, 16, Endian.little); // bit mỗi mẫu
  ascii(36, 'data');
  bytes.setUint32(40, dataBytes, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final value = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(headerBytes + i * 2, value, Endian.little);
  }
  return bytes.buffer.asUint8List();
}

/// Tiếng to nhất trong đoạn ghi (0..1). Đoạn gần như im lặng thì không gửi đi:
/// Whisper hay "nghe" ra câu vu vơ từ tiếng ồn.
double peakLevel(Float32List samples) =>
    samples.fold<double>(0, (peak, value) => math.max(peak, value.abs()));
