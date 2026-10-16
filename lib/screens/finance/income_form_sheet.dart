import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/income.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common.dart';

/// Formulario para registrar un ingreso neto de un trabajo que no es campaña.
Future<void> showIncomeForm(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _IncomeForm(),
  );
}

class _IncomeForm extends StatefulWidget {
  const _IncomeForm();

  @override
  State<_IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<_IncomeForm> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.').trim());
    if (_title.text.trim().isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un concepto y un importe válido')),
      );
      return;
    }
    await context.read<FinanceProvider>().addIncome(
      Income(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        amount: amount,
        date: _date,
      ),
    );
    if (!mounted) return;
    Navigator.pop(context);
    showToast(
      context,
      'Ingreso guardado',
      subtitle: '${euro(amount)} netos sumados a tu mes',
      emoji: '💼',
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Nuevo ingreso neto', style: AppText.headlineMd),
            Text(
              'Trabajos fuera de campañas. Se suma íntegro: sin IVA, IRPF ni agencia.',
              style: AppText.bodySm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Concepto (ej. Edición de vídeo freelance)',
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
                    decoration: const InputDecoration(
                      hintText: 'Importe neto',
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
            PrimaryButton(
              label: 'Guardar ingreso',
              icon: Icons.work_outline,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
