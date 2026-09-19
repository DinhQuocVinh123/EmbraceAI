import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/journal_repository.dart';
import 'state/journal_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nạp dữ liệu định dạng ngày tiếng Việt trước khi dựng giao diện.
  await initializeDateFormatting('vi');

  final repository = JournalRepository(AppDatabase());

  runApp(
    ChangeNotifierProvider(
      create: (_) => JournalStore(repository)..load(),
      child: const EmbraceApp(),
    ),
  );
}
