import 'package:cairn/core/formatting/amount_parser.dart';
import 'package:cairn/core/money/currency.dart';
import 'package:cairn/features/manual_entry/domain/portfolio_writer.dart';
import 'package:cairn/features/manual_entry/presentation/form_widgets.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:cairn/shared/labels/domain_labels.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Types proposés à la saisie (le découvert est déduit des comptes).
const List<LiabilityType> _editableTypes = [
  LiabilityType.mortgage,
  LiabilityType.autoLoan,
  LiabilityType.personalLoan,
  LiabilityType.studentLoan,
  LiabilityType.creditCard,
  LiabilityType.other,
];

class LiabilityFormScreen extends ConsumerStatefulWidget {
  const LiabilityFormScreen({super.key, this.liabilityId});

  final String? liabilityId;

  @override
  ConsumerState<LiabilityFormScreen> createState() => _LiabilityFormScreenState();
}

class _LiabilityFormScreenState extends ConsumerState<LiabilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _institution = TextEditingController();
  LiabilityType _type = LiabilityType.mortgage;
  String _currency = 'EUR';
  String? _securedAssetId;
  bool _saving = false;
  LiabilityItem? _existing;
  List<AssetItem> _realEstate = const [];

  @override
  void initState() {
    super.initState();
    final overview = ref.read(financialOverviewProvider).value;
    _currency = overview?.breakdown.currency.code ?? 'EUR';
    _realEstate = [
      for (final asset in overview?.assets ?? const <AssetItem>[])
        if (asset.assetClass == AssetClass.realEstate) asset,
    ];
    final id = widget.liabilityId;
    for (final liability in overview?.liabilities ?? const <LiabilityItem>[]) {
      if (liability.id == id) {
        _existing = liability;
      }
    }
    final existing = _existing;
    if (existing != null) {
      _name.text = existing.name;
      _amount.text = existing.outstanding.major.toStringAsFixed(existing.outstanding.currency.decimalDigits);
      _institution.text = existing.institutionName ?? '';
      _type = _editableTypes.contains(existing.type) ? existing.type : LiabilityType.other;
      _currency = existing.outstanding.currency.code;
      _securedAssetId = _realEstate.any((a) => a.id == existing.securedAssetId) ? existing.securedAssetId : null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _institution.dispose();
    super.dispose();
  }

  String? _validateAmount(String? text) {
    final value = parseAmount(text ?? '', Currency.of(_currency));
    if (value == null) {
      return 'Montant invalide (exemple : 185 000).';
    }
    if (value.isNegative) {
      return 'Indique le capital restant dû, sans signe moins.';
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
      await writer.saveLiability(
        LiabilityDraft(
          id: _existing?.id,
          name: _name.text,
          type: _type,
          outstanding: parseAmount(_amount.text, Currency.of(_currency))!,
          institutionName: _institution.text,
          securedAssetId: _type == LiabilityType.mortgage ? _securedAssetId : null,
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
      await writer.deleteLiability(existing.id);
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
        title: Text(editing ? 'Modifier une dette' : 'Ajouter une dette'),
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
                  hintText: 'Crédit immobilier, prêt auto…',
                  border: OutlineInputBorder(),
                ),
                validator: (text) => (text ?? '').trim().isEmpty ? 'Donne un nom à cette dette.' : null,
              ),
              formGap,
              DropdownButtonFormField<LiabilityType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: [
                  for (final t in _editableTypes)
                    DropdownMenuItem(value: t, child: Text(DomainLabels.liabilityType(t))),
                ],
                onChanged: (value) => setState(() => _type = value ?? _type),
              ),
              formGap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Capital restant dû',
                        border: OutlineInputBorder(),
                      ),
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
              if (_type == LiabilityType.mortgage && _realEstate.isNotEmpty) ...[
                formGap,
                DropdownButtonFormField<String?>(
                  initialValue: _securedAssetId,
                  decoration: const InputDecoration(
                    labelText: 'Bien financé (facultatif)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(child: Text('Aucun')),
                    for (final asset in _realEstate)
                      DropdownMenuItem<String?>(value: asset.id, child: Text(asset.name)),
                  ],
                  onChanged: (value) => setState(() => _securedAssetId = value),
                ),
              ],
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
            ],
          ),
        ),
      ),
    );
  }
}
