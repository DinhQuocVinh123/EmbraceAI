import 'dart:io';

Future<void> main() async {
  const configPath = 'config/supabase.json';
  if (!File(configPath).existsSync()) {
    stderr.writeln(
      'Missing $configPath. Copy config/supabase.example.json and add the '
      'Supabase project URL and publishable key before deploying.',
    );
    exitCode = 1;
    return;
  }

  final process = await Process.start(
    'flutter',
    const [
      'build',
      'web',
      '--release',
      '--dart-define-from-file=config/supabase.json',
    ],
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  exitCode = await process.exitCode;
}
