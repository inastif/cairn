import 'package:cairn/core/formatting/amount_parser.dart';
import 'package:cairn/core/money/currency.dart';
import 'package:cairn/features/manual_entry/domain/portfolio_writer.dart';
import 'package:cairn/features/manual_entry/presentation/form_widgets.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:cairn/shared/labels/domain_labels.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Création ou modification d'un actif saisi à la main.
class AssetFormScreen extends ConsumerStatefulWidget {
  const AssetFormScreen({super.key, this.assetId});

  final String? assetId;

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _subtype = TextEditingController();
  final _institution = TextEditingController();
  AssetClass _assetClass = AssetClass.cash;
  String _currency = 'EUR';
  bool _saving = false;
  AssetItem? _existing;

  @override
  void initState() {
    super.initState();
    final overview = ref.read(financialOverviewProvider).value;
    _currency = overview?.breakdown.currency.code ?? 'EUR';
    final id = widget.assetId;
    if (id != null && overview != null) {
      for (final asset in overview.assets) {
        if (asset.id == id) {
          _existing = asset;
        }
      }
    }
    final existing = _existing;
    if (existing != null) {
      _name.text = existing.name;
      _amount.text = existing.value.major.toStringAsFixed(existing.value.currency.decimalDigits);
      _subtype.text = existing.subtype ?? '';
      _institution.text = existing.institutionName ?? '';
      _assetClass = existing.assetClass;
      _currency = existing.value.currency.code;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _subtype.dispose();
    _institution.dispose();
    super.dispose();
  }

  String? _validateAmount(String? text) {
    final value = parseAmount(text ?? '', Currency.of(_currency));
    if (value == null) {
      return 'Montant invalide (exemple : 12 500,50).';
    }
    if (value.isNegative && _assetClass != AssetClass.cash) {
      return 'Seul un compte en liquidités peut être négatif (découvert).';
    }
    return null;
  }

  Future<void> _save() async {
    final writer = ref.read(portfolioWriterProvider);
    if (writer == null || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    try {
      await writer.saveAsset(
        AssetDraft(
          id: _existing?.id,
          name: _name.text,
          assetClass: _assetClass,
          value: parseAmount(_amount.text, Currency.of(_currency))!,
          subtype: _subtype.text,
          institutionName: _institution.text,
        ),
      );
      ref.invalidate(financialOverviewProvider);
      if (mounted) {
        context.pop();
      }
    } on PortfolioWriteException catch (error) {
      if (mounted) {
        showError(context, error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final existing = _existing;
    final writer = ref.read(portfolioWriterProvider);
    if (existing == null || writer == null || !await confirmDeletion(context, existing.name)) {
      return;
    }
    try {
      await writer.deleteAsset(existing.id);
      ref.invalidate(financialOverviewProvider);
      if (mounted) {
        context.pop();
      }
    } on PortfolioWriteException catch (error) {
      if (mounted) {
        showError(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = _existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Modifier un actif' : 'Ajouter un actif'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _saving ? null : _delete,
              icon: Icon(Icons.delete_outline_rounded, color: context.colors.negative),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Livret A, PEA, appartement…',
                  border: OutlineInputBorder(),
                ),
                validator: (text) => (text ?? '').trim().isEmpty ? 'Donne un nom à cet actif.' : null,
              ),
              formGap,
              DropdownButtonFormField<AssetClass>(
                initialValue: _assetClass,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: [
                  for (final c in AssetClass.values)
                    DropdownMenuItem(value: c, child: Text(DomainLabels.assetClass(c))),
                ],
                onChanged: (value) => setState(() => _assetClass = value ?? _assetClass),
              ),
              formGap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Valeur', border: OutlineInputBorder()),
                      validator: _validateAmount,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: CurrencyField(
                      value: _currency,
                      onChanged: (code) => setState(() => _currency = code),
                    ),
                  ),
                ],
              ),
              formGap,
              TextFormField(
                controller: _subtype,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Précision (facultatif)',
                  hintText: 'Résidence principale, ETF monde…',
                  border: OutlineInputBorder(),
                ),
              ),
              formGap,
              TextFormField(
                controller: _institution,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Établissement (facultatif)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(editing ? 'Enregistrer' : 'Ajouter'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Pour un bien immobilier ou un placement, indique ta meilleure estimation '
                'actuelle. Tu pourras la mettre à jour à tout moment.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
