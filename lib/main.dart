import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/prefs_journal_repository.dart';
import 'state/journal_store.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nạp dữ liệu định dạng ngày trước khi dựng giao diện.
  await initializeDateFormatting('en');

  final settings = SettingsStore();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => JournalStore(PrefsJournalRepository())..load(),
        ),
      ],
      child: const EmbraceApp(),
    ),
  );
}
