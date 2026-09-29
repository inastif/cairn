import 'package:cairn/config/app_config.dart';
import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/core/clock/clock_provider.dart';
import 'package:cairn/features/security/application/app_lock_controller.dart';
import 'package:cairn/routing/app_router.dart';
import 'package:cairn/shared/settings/app_settings.dart';
import 'package:cairn/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CairnApp extends ConsumerStatefulWidget {
  const CairnApp({super.key});

  /// Au-delà de cette durée en arrière-plan, le code est redemandé.
  static const Duration relockAfter = Duration(seconds: 60);

  @override
  ConsumerState<CairnApp> createState() => _CairnAppState();
}

class _CairnAppState extends ConsumerState<CairnApp> {
  late final AppLifecycleListener _lifecycle;
  DateTime? _hiddenAt;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onHide() => _hiddenAt = ref.read(clockProvider)();

  void _onShow() {
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null || ref.read(isDemoModeProvider)) {
      return;
    }
    if (ref.read(clockProvider)().difference(hiddenAt) >= CairnApp.relockAfter) {
      ref.read(appLockProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
