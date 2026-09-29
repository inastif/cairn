import 'package:cairn/config/app_config.dart';
import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/core/money/currency.dart';
import 'package:cairn/features/auth/application/auth_providers.dart';
import 'package:cairn/features/auth/application/session_actions.dart';
import 'package:cairn/features/auth/domain/auth_repository.dart';
import 'package:cairn/features/demo/data/demo_profiles.dart';
import 'package:cairn/features/manual_entry/domain/portfolio_writer.dart';
import 'package:cairn/features/manual_entry/presentation/form_widgets.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:cairn/features/security/application/app_lock_controller.dart';
import 'package:cairn/routing/app_routes.dart';
import 'package:cairn/shared/settings/app_settings.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final demo = ref.watch(isDemoModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxxl),
        children: [
          if (demo) const _DemoSection() else const _AccountSection(),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle('Banques'),
          const Panel(
            padding: EdgeInsets.zero,
            child: ListTile(
              enabled: false,
              leading: Icon(Icons.account_balance_outlined),
              title: Text('Connecter ma banque'),
              subtitle: Text(
                'Disponible une fois le fournisseur Open Banking contractualisé. '
                'Tes identifiants bancaires ne seront jamais saisis dans l’application.',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _DisplaySection(),
          if (!demo) ...[
            const SizedBox(height: AppSpacing.xl),
            const _DangerSection(),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${AppConfig.appName} 0.2.0, environnement ${AppConfig.environment.name}'
            '${demo ? ', mode démonstration' : ''}.',
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DemoSection extends ConsumerWidget {
  const _DemoSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final selected = ref.watch(demoProfileProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Profil de démonstration'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final profile in DemoProfileId.values)
                ListTile(
                  title: Text(profile.label),
                  subtitle: Text(profile.description),
                  selected: profile == selected,
                  selectedColor: colors.textPrimary,
                  trailing: profile == selected
                      ? Icon(Icons.check_rounded, color: colors.accent, semanticLabel: 'Sélectionné')
                      : null,
                  onTap: () => ref.read(demoProfileProvider.notifier).select(profile),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _changeCurrency(BuildContext context, WidgetRef ref, String code) async {
    final writer = ref.read(portfolioWriterProvider);
    if (writer == null) {
      return;
    }
    try {
      await writer.updateReportingCurrency(Currency.of(code));
      ref.invalidate(financialOverviewProvider);
    } on PortfolioWriteException catch (error) {
      if (context.mounted) {
        showError(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authRepositoryProvider)?.email ?? '';
    final currency = ref.watch(financialOverviewProvider).value?.breakdown.currency.code;
    final lock = ref.watch(appLockProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Compte'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: AppSpacing.lg),
              if (currency != null)
                CurrencyField(
                  key: ValueKey(currency),
                  value: currency,
                  onChanged: (code) => _changeCurrency(context, ref, code),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Devise de référence : ton patrimoine et l’objectif de 1 000 000 sont exprimés dans cette devise.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle('Sécurité'),
        Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: const Text('Changer le code'),
                onTap: () => context.push(AppRoutes.changePin),
              ),
              if (lock?.biometricAvailable ?? false)
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Déverrouiller avec la biométrie'),
                  value: lock?.biometricEnabled ?? false,
                  onChanged: (value) =>
                      ref.read(appLockProvider.notifier).setBiometricEnabled(enabled: value),
                ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Se déconnecter'),
                onTap: () => SessionActions.signOut(ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisplaySection extends ConsumerWidget {
  const _DisplaySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final privacy = ref.watch(privacyModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Affichage'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thème', style: text.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Système')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Clair')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Sombre')),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) => ref.read(themeModeProvider.notifier).select(selection.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Masquer les montants'),
                subtitle: const Text('Utile pour consulter l’application en public.'),
                value: privacy,
                onChanged: (value) => ref.read(privacyModeProvider.notifier).set(enabled: value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DangerSection extends ConsumerWidget {
  const _DangerSection();

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ton compte ?'),
        content: const Text(
          'Ton compte, tes actifs, tes dettes et ton historique seront définitivement effacés. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.negative),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) {
      return;
    }
    try {
      await SessionActions.deleteAccount(ref);
    } on AuthFailure catch (failure) {
      if (context.mounted) {
        showError(context, failure.message);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Données personnelles'),
        Panel(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: colors.negative),
            title: Text('Supprimer mon compte et mes données', style: TextStyle(color: colors.negative)),
            onTap: () => _delete(context, ref),
          ),
        ),
      ],
    );
  }
}
