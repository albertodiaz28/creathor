import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common.dart';

Future<void> showExpenseForm(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ExpenseForm(),
  );
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm();

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.software;
  double _deductible = 100;
  bool _receipt = true;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  double? get _parsedAmount =>
      double.tryParse(_amount.text.replaceAll(',', '.').trim());

  Future<void> _save() async {
    final amount = _parsedAmount;
    if (_title.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un concepto y un importe válido')),
      );
      return;
    }
    final finance = context.read<FinanceProvider>();
    await finance.addExpense(
      Expense(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        amount: amount,
        category: _category,
        date: _date,
        deductiblePct: _deductible,
        hasReceipt: _receipt,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    showToast(
      context,
      'Gasto guardado',
      subtitle: 'IVA recuperable actualizado',
      emoji: '🧾',
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _parsedAmount ?? 0;
    final vat =
        amount * _deductible / 100 * Expense.vatRate / (1 + Expense.vatRate);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.margin,
        right: AppSpacing.margin,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nuevo gasto deducible', style: AppText.headlineMd),
            Text(
              'Microgastos del estudio: software, luz, fibra, atrezzo…',
              style: AppText.bodySm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Concepto (ej. Adobe Creative Cloud)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Nota opcional'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Importe',
                      suffixText: '€',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.event_outlined, size: 20),
                      ),
                      child: Text(shortDate(_date), style: AppText.bodyMd),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'CATEGORÍA',
              style: AppText.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ExpenseCategory.values)
                  PillChip(
                    label: c.label,
                    icon: c.icon,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text('Parte deducible', style: AppText.titleSm),
                ),
                Text('${_deductible.round()}%', style: AppText.numericStat),
              ],
            ),
            Slider(
              value: _deductible,
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: AppColors.secondary,
              onChanged: (v) => setState(() => _deductible = v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _receipt,
              activeThumbColor: AppColors.secondary,
              title: Text('Ticket / factura guardada', style: AppText.bodyMd),
              onChanged: (v) => setState(() => _receipt = v),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'IVA recuperable estimado: ${euro(vat)}',
                      style: AppText.labelLg.copyWith(
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Guardar gasto',
              icon: Icons.receipt_long_outlined,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
