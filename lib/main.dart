import 'package:cairn/app.dart';
import 'package:cairn/config/supabase_config.dart';
import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/features/auth/data/secure_session_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final config = SupabaseConfig.fromEnvironment();
  if (!config.isConfigured) {
    // Pas de backend configuré : profils de démonstration uniquement.
    runApp(const ProviderScope(child: CairnApp()));
    return;
  }

  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
    authOptions: FlutterAuthClientOptions(
      // Sur mobile, la session est rangée dans le Keychain / Keystore.
      localStorage: kIsWeb ? null : const SecureSessionStorage(),
    ),
    debug: false,
  );
  runApp(
    ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(Supabase.instance.client)],
      child: const CairnApp(),
    ),
  );
}
