import 'package:cairn/features/auth/application/auth_providers.dart';
import 'package:cairn/features/security/application/app_lock_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Actions qui touchent à la fois au compte et au verrou local.
abstract final class SessionActions {
  static Future<void> signOut(WidgetRef ref) async {
    await ref.read(appLockProvider.notifier).clear();
    await ref.read(authRepositoryProvider)?.signOut();
  }

  static Future<void> deleteAccount(WidgetRef ref) async {
    await ref.read(authRepositoryProvider)?.deleteAccount();
    await ref.read(appLockProvider.notifier).clear();
  }
}
