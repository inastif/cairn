import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/shared/settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche un montant en respectant le mode confidentialité.
/// C'est le SEUL widget autorisé à afficher un montant.
class AmountText extends ConsumerWidget {
  const AmountText(
    this.value, {
    super.key,
    this.style,
    this.signed = false,
    this.decimals = 0,
    this.textAlign,
  });

  final Money value;
  final TextStyle? style;
  final bool signed;
  final int decimals;
  final TextAlign? textAlign;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    final text = hidden
        ? _format.maskedMoney(value.currency)
        : _format.money(value, signed: signed, decimals: decimals);
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: hidden ? 'Montant masqué' : null,
    );
  }
}

/// Texte dérivé d'un montant (pourcentage millionnaire, variation relative)
/// qui doit lui aussi disparaître en mode confidentialité.
class PrivateText extends ConsumerWidget {
  const PrivateText(this.text, {super.key, this.style, this.masked = '••,••\u00A0%'});

  final String text;
  final String masked;
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    return Text(
      hidden ? masked : text,
      style: style,
      maxLines: 1,
      semanticsLabel: hidden ? 'Valeur masquée' : null,
    );
  }
}
