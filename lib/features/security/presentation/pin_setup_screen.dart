import 'package:cairn/features/security/application/app_lock_controller.dart';
import 'package:cairn/features/security/domain/pin_hasher.dart';
import 'package:cairn/features/security/presentation/pin_input.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Step { current, choose, confirm }

/// Création du code après la première connexion, ou changement de code
/// (le code actuel est alors demandé d'abord).
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.isChange = false});

  final bool isChange;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _controller = TextEditingController();
  late _Step _step = widget.isChange ? _Step.current : _Step.choose;
  String _chosen = '';
  String? _error;
  bool _busy = false;
  bool _enableBiometrics = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _restart(String? error) {
    _controller.clear();
    setState(() {
      _step = _Step.choose;
      _chosen = '';
      _error = error;
    });
  }

  Future<void> _onCompleted(String pin) async {
    if (_busy) {
      return;
    }
    switch (_step) {
      case _Step.current:
        setState(() => _busy = true);
        final result = await ref.read(appLockProvider.notifier).checkPin(pin, unlock: false);
        if (!mounted) {
          return;
        }
        _controller.clear();
        setState(() {
          _busy = false;
          if (result is PinAccepted) {
            _step = _Step.choose;
            _error = null;
          } else {
            _error = 'Code actuel incorrect.';
          }
        });
      case _Step.choose:
        if (isWeakPin(pin)) {
          _restart('Code trop simple. Évite les suites et les chiffres répétés.');
          return;
        }
        _controller.clear();
        setState(() {
          _chosen = pin;
          _step = _Step.confirm;
          _error = null;
        });
      case _Step.confirm:
        if (pin != _chosen) {
          _restart('Les deux codes ne correspondent pas. Recommence.');
          return;
        }
        setState(() => _busy = true);
        final lock = ref.read(appLockProvider).value;
        await ref.read(appLockProvider.notifier).setupPin(
              pin,
              enableBiometrics: (lock?.biometricAvailable ?? false) && _enableBiometrics,
            );
        if (mounted && widget.isChange) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code modifié.')));
          context.pop();
        }
        // En création, la redirection vers l'accueil est automatique.
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final biometricAvailable = ref.watch(appLockProvider).value?.biometricAvailable ?? false;
    final (title, subtitle) = switch (_step) {
      _Step.current => ('Code actuel', 'Saisis ton code actuel pour le modifier.'),
      _Step.choose => (
          widget.isChange ? 'Nouveau code' : 'Protège ton accès',
          'Choisis un code à 6 chiffres. Il sera demandé à chaque ouverture de '
              "l'application sur cet appareil.",
        ),
      _Step.confirm => ('Confirme ton code', 'Saisis le même code une seconde fois.'),
    };

    return Scaffold(
      appBar: widget.isChange ? AppBar(title: const Text('Changer le code')) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.screen),
              children: [
                Text(title, style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(subtitle, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                PinInput(
                  key: ValueKey(_step),
                  controller: _controller,
                  onCompleted: _onCompleted,
                  errorText: _error,
                  enabled: !_busy,
                ),
                if (_step != _Step.current && biometricAvailable) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Déverrouiller aussi avec la biométrie'),
                    subtitle: const Text('Empreinte ou reconnaissance faciale de cet appareil.'),
                    value: _enableBiometrics,
                    onChanged: (value) => setState(() => _enableBiometrics = value),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
