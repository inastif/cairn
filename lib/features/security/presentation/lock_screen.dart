import 'package:cairn/config/app_config.dart';
import 'package:cairn/core/clock/clock_provider.dart';
import 'package:cairn/features/auth/application/session_actions.dart';
import 'package:cairn/features/security/application/app_lock_controller.dart';
import 'package:cairn/features/security/presentation/pin_input.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Propose la biométrie dès l'ouverture si elle est activée.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometrics());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tryBiometrics() async {
    final lock = ref.read(appLockProvider).value;
    if (lock == null || !lock.canUseBiometrics || !mounted) {
      return;
    }
    await ref.read(appLockProvider.notifier).unlockWithBiometrics();
  }

  Future<void> _submit(String pin) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(appLockProvider.notifier).checkPin(pin);
    if (!mounted) {
      return;
    }
    _controller.clear();
    final now = ref.read(clockProvider)();
    setState(() {
      _busy = false;
      _error = switch (result) {
        PinAccepted() => null,
        PinRejected(:final attemptsBeforeLockout) => attemptsBeforeLockout == null
            ? 'Code incorrect.'
            : 'Code incorrect. Encore $attemptsBeforeLockout essai(s) avant un blocage temporaire.',
        PinLockedOut(:final until) =>
          'Trop d’essais. Réessaie dans ${until.difference(now).inSeconds + 1} s.',
        PinWiped() => null,
      };
    });
    if (result is PinWiped) {
      await SessionActions.signOut(ref);
    }
  }

  Future<void> _forgot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code oublié ?'),
        content: const Text(
          'Tu vas être déconnecté. Reconnecte-toi avec ton e-mail puis choisis un nouveau code. '
          'Tes données restent sauvegardées.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (confirmed ?? false) {
      await SessionActions.signOut(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lock = ref.watch(appLockProvider).value;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text(AppConfig.appName, style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text('Saisis ton code pour accéder à tes données.', style: text.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                PinInput(controller: _controller, onCompleted: _submit, errorText: _error, enabled: !_busy),
                const SizedBox(height: AppSpacing.lg),
                if (lock?.canUseBiometrics ?? false)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _tryBiometrics,
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('Utiliser la biométrie'),
                  ),
                TextButton(onPressed: _busy ? null : _forgot, child: const Text('Code oublié')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
