import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/backend_config.dart';
import 'screens/access_gate.dart';
import 'screens/backend_setup_screen.dart';
import 'services/study_assessment_service.dart';
import 'state/auth_store.dart';
import 'state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (BackendConfig.isConfigured) {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
    );
  }
  // Nạp dữ liệu định dạng ngày trước khi dựng giao diện.
  await initializeDateFormatting('en');

  final settings = SettingsStore();
  await settings.load();

  final providers = <SingleChildWidget>[
    ChangeNotifierProvider.value(value: settings),
    if (BackendConfig.isConfigured)
      ChangeNotifierProvider(create: (_) => AuthStore()),
    if (BackendConfig.isConfigured)
      Provider(create: (_) => StudyAssessmentService()),
  ];

  runApp(
    MultiProvider(
      providers: providers,
      child: EmbraceApp(
        home: BackendConfig.isConfigured
            ? const AccessGate()
            : const BackendSetupScreen(),
      ),
    ),
  );
}
