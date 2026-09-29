import 'package:cairn/features/security/domain/pin_hasher.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de code à 6 chiffres. Utilise le clavier système (accessible,
/// compatible lecteurs d'écran) et valide automatiquement au 6e chiffre.
class PinInput extends StatelessWidget {
  const PinInput({
    required this.controller,
    required this.onCompleted,
    super.key,
    this.label = 'Code à 6 chiffres',
    this.errorText,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final String label;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      obscureText: true,
      obscuringCharacter: '●',
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: pinLength,
      autofillHints: const [],
      enableSuggestions: false,
      autocorrect: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(letterSpacing: AppSpacing.md),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorMaxLines: 3,
        counterText: '',
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        if (value.length == pinLength) {
          onCompleted(value);
        }
      },
    );
  }
}
