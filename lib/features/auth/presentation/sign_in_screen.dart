import 'dart:async';

import 'package:cairn/config/app_config.dart';
import 'package:cairn/features/auth/application/auth_providers.dart';
import 'package:cairn/features/auth/domain/auth_repository.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connexion sans mot de passe : e-mail, puis code reçu par e-mail.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  static const int _resendDelaySeconds = 60;

  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _resendIn = _resendDelaySeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _resendIn <= 1) {
        timer.cancel();
      }
      if (mounted) {
        setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      }
    });
  }

  Future<void> _run(Future<void> Function(AuthRepository repository) action) async {
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(repository);
    } on AuthFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sendCode() => _run((repository) async {
        await repository.sendCode(_email.text);
        if (mounted) {
          setState(() => _codeSent = true);
          _startCooldown();
        }
      });

  // La redirection vers la création du code est automatique après succès.
  Future<void> _verify() =>
      _run((repository) => repository.verifyCode(email: _email.text, code: _code.text));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
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
                Text(
                  _codeSent
                      ? 'Saisis le code reçu à ${_email.text.trim()}. Pense à vérifier les courriers indésirables.'
                      : 'Connecte-toi avec ton e-mail : tu recevras un code à usage unique. '
                          'Aucun mot de passe à retenir.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _email,
                  enabled: !_codeSent && !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Adresse e-mail', border: OutlineInputBorder()),
                  onSubmitted: (_) => _sendCode(),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _code,
                    enabled: !_busy,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    decoration: const InputDecoration(
                      labelText: 'Code reçu par e-mail',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                ],
                if (_error case final message?) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(message, style: text.bodyMedium?.copyWith(color: colors.negative)),
                ],
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                  child: _busy
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_codeSent ? 'Se connecter' : 'Recevoir un code'),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _busy || _resendIn > 0 ? null : _sendCode,
                    child: Text(_resendIn > 0 ? 'Renvoyer le code dans $_resendIn s' : 'Renvoyer le code'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _code.clear();
                              _error = null;
                            }),
                    child: const Text("Changer d'adresse"),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Tes données sont liées à ton compte et accessibles à toi seul. '
                  'Tu peux les supprimer à tout moment depuis ton profil.',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
