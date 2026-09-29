import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode confidentialité : masque tous les montants (et le pourcentage
/// millionnaire, qui révèle le patrimoine) pour un usage en public.
final class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;

  void set({required bool enabled}) => state = enabled;
}

final privacyModeProvider = NotifierProvider<PrivacyModeNotifier, bool>(PrivacyModeNotifier.new);

final class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void select(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
