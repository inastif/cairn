import 'package:cairn/core/money/supported_currencies.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Espacement standard des formulaires de saisie.
const SizedBox formGap = SizedBox(height: AppSpacing.lg);

class CurrencyField extends StatelessWidget {
  const CurrencyField({required this.value, required this.onChanged, super.key});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final codes = supportedCurrencyCodes.contains(value)
        ? supportedCurrencyCodes
        : [value, ...supportedCurrencyCodes];
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Devise', border: OutlineInputBorder()),
      items: [for (final code in codes) DropdownMenuItem(value: code, child: Text(code))],
      onChanged: (code) {
        if (code != null) {
          onChanged(code);
        }
      },
    );
  }
}

Future<bool> confirmDeletion(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer cet élément ?'),
      content: Text('« $name » sera retiré de ton patrimoine et de ton historique futur.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
      ],
    ),
  );
  return result ?? false;
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
