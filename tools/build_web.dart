import 'dart:io';

/// Build hai bản web từ cùng một code.
///
///   dart run tools/build_web.dart              # cả hai
///   dart run tools/build_web.dart participant  # build/web
///   dart run tools/build_web.dart staff        # build/web_staff
///
/// Bản staff không phát video nên thư mục video (khoảng 400 MB) bị bỏ khỏi
/// bản đó: deploy nhanh hơn và không tốn dung lượng hosting.
Future<void> main(List<String> args) async {
  const configPath = 'config/supabase.json';
  if (!File(configPath).existsSync()) {
    stderr.writeln(
      'Missing $configPath. Copy config/supabase.example.json and add the '
      'Supabase project URL and publishable key before deploying.',
    );
    exitCode = 1;
    return;
  }

  final targets = args.isEmpty ? const ['participant', 'staff'] : args;
  for (final target in targets) {
    if (target != 'participant' && target != 'staff') {
      stderr.writeln('Unknown target "$target". Use participant or staff.');
      exitCode = 64;
      return;
    }
    final output = Directory(
      target == 'staff' ? 'build/web_staff' : 'build/web',
    ).absolute.path;
    stdout.writeln('Building $target web app into $output');
    final process = await Process.start(
      'flutter',
      [
        'build',
        'web',
        '--release',
        '--dart-define-from-file=$configPath',
        '--dart-define=APP_SURFACE=$target',
        '--output=$output',
      ],
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final code = await process.exitCode;
    if (code != 0) {
      exitCode = code;
      return;
    }
    if (target == 'staff') {
      final videos = Directory('$output/assets/assets/video');
      if (videos.existsSync()) videos.deleteSync(recursive: true);
    }
  }
}
