import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/income.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common.dart';
import 'income_form_sheet.dart';

/// Lista de ingresos netos del mes que no proceden de campañas.
class IncomesSection extends StatelessWidget {
  const IncomesSection({super.key, required this.finance});
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = finance.incomes
        .where((i) => i.date.year == now.year && i.date.month == now.month)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Otros ingresos',
          subtitle: 'Trabajos fuera de campañas · importe neto',
          trailing: RoundIconButton(
            icon: Icons.add,
            bg: AppColors.surfaceContainerHigh,
            fg: AppColors.onSurface,
            tooltip: 'Añadir ingreso neto',
            onTap: () => showIncomeForm(context),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.work_outline,
            title: 'Sin otros ingresos este mes',
            subtitle:
                'Añade trabajos freelance, clases o colaboraciones ya cobradas en neto.',
          )
        else
          SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _IncomeRow(income: items[i], finance: finance),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({required this.income, required this.finance});
  final Income income;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final i = income;
    return Dismissible(
      key: ValueKey('income-${i.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) => confirmDialog(
        context,
        title: 'Eliminar ingreso',
        message: '¿Quitar "${i.title}" de tus ingresos?',
      ),
      onDismissed: (_) => finance.deleteIncome(i.id!),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondaryContainer.withValues(
                alpha: 0.4,
              ),
              child: const Icon(
                Icons.work_outline,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.title,
                    style: AppText.titleSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    i.description ?? shortDate(i.date),
                    style: AppText.bodySm.copyWith(color: AppColors.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  finance.hideAmounts ? '••••' : '+${euro(i.amount)}',
                  style: AppText.numericStat.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Neto',
                  style: AppText.labelSm.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
