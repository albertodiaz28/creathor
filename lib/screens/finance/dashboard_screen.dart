import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/campaign.dart';
import '../../models/expense.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common.dart';
import 'campaign_detail_screen.dart';
import 'expense_form_sheet.dart';
import 'income_form_sheet.dart';
import 'incomes_section.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onNewCampaign});

  final VoidCallback onNewCampaign;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    if (!finance.loaded) {
      return const Scaffold(
        appBar: AppHeader(section: 'Finanzas'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const AppHeader(section: 'Finanzas'),
      body: RefreshIndicator(
        onRefresh: finance.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.margin,
            AppSpacing.sm,
            AppSpacing.margin,
            AppSpacing.xl,
          ),
          children: [
            const _Greeting(),
            const SizedBox(height: AppSpacing.lg),
            _HeroBalanceCard(finance: finance),
            const SizedBox(height: AppSpacing.lg),
            _CampaignsSection(finance: finance),
            const SizedBox(height: AppSpacing.lg),
            IncomesSection(finance: finance),
            const SizedBox(height: AppSpacing.lg),
            _ExpensesSection(finance: finance),
            const SizedBox(height: AppSpacing.lg),
            _TipCard(finance: finance),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: 'Nueva Campaña',
                    icon: Icons.add_circle_outline,
                    onPressed: onNewCampaign,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                RoundIconButton(
                  icon: Icons.work_outline,
                  size: 48,
                  iconSize: 20,
                  bg: AppColors.secondaryContainer,
                  fg: AppColors.onSecondaryContainer,
                  tooltip: 'Añadir ingreso neto',
                  onTap: () => showIncomeForm(context),
                ),
                const SizedBox(width: AppSpacing.sm),
                RoundIconButton(
                  icon: Icons.receipt_outlined,
                  size: 48,
                  iconSize: 20,
                  bg: AppColors.surfaceContainerHighest,
                  fg: AppColors.onSurface,
                  tooltip: 'Añadir gasto',
                  onTap: () => showExpenseForm(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TUS NÚMEROS CLAROS',
                style: AppText.labelSm.copyWith(color: AppColors.outline),
              ),
              Text('Finanzas & Deals ✨', style: AppText.headlineLg),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(monthYear(DateTime.now()), style: AppText.labelSm),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.finance});
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final s = finance.monthSummary;
    final hidden = finance.hideAmounts;
    String money(num v) => hidden ? '••••' : euroInt(v);

    return SurfaceCard(
      clip: true,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -48,
            child: _Glow(
              color: AppColors.secondaryFixed.withValues(alpha: 0.25),
              size: 176,
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: _Glow(
              color: AppColors.tertiaryFixed.withValues(alpha: 0.35),
              size: 144,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Para ti este mes',
                            style: AppText.labelLg.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const Tag(
                            label: 'Limpio ✌️',
                            bg: Color(0x6650FBB1),
                            fg: AppColors.onSecondaryContainer,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onTap: finance.toggleHideAmounts,
                      tooltip: hidden ? 'Mostrar importes' : 'Ocultar importes',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hidden ? '••••,••' : euroPlain(s.net),
                      style: AppText.headlineXlMobile,
                    ),
                    const SizedBox(width: 4),
                    Text('€', style: AppText.headlineMd),
                  ],
                ),
                Text(
                  'Campañas tras IVA (21%) y agencia, menos gastos, más otros ingresos netos',
                  style: AppText.bodySm.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedBar(
                  segments: [
                    (s.netPct, AppColors.secondaryFixedDim),
                    (s.taxPct, AppColors.error),
                    (s.agencyPct, AppColors.onTertiaryContainer),
                    (s.expensesPct, AppColors.outline),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    LegendDot(
                      color: AppColors.secondaryFixedDim,
                      label: '${percent(s.netPct * 100)} Neto',
                    ),
                    LegendDot(
                      color: AppColors.error,
                      label: '${percent(s.taxPct * 100)} Hacienda',
                    ),
                    LegendDot(
                      color: AppColors.onTertiaryContainer,
                      label: '${percent(s.agencyPct * 100)} Agencia',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _StatTile(
                      label: 'Facturado Bruto',
                      value: money(s.gross),
                      icon: Icons.trending_up,
                      iconColor: AppColors.onSurface,
                    ),
                    _StatTile(
                      label: 'Hucha Hacienda',
                      value: hidden ? '••••' : '-${euroInt(s.tax)}',
                      icon: Icons.account_balance_outlined,
                      iconColor: AppColors.error,
                      valueColor: AppColors.error,
                    ),
                    _StatTile(
                      label: 'Comisión Agencia',
                      value: hidden ? '••••' : '-${euroInt(s.agency)}',
                      icon: Icons.hub_outlined,
                      iconColor: AppColors.onTertiaryContainer,
                      valueColor: AppColors.onTertiaryContainer,
                    ),
                    _StatTile(
                      label: 'Gastos Deducibles',
                      value: hidden ? '••••' : '-${euroInt(s.expenses)}',
                      icon: Icons.receipt_long_outlined,
                      iconColor: AppColors.outline,
                      valueColor: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: _StatTile(
                    label: 'Otros ingresos netos (sin IVA ni IRPF)',
                    value: hidden ? '••••' : '+${euroInt(s.otherIncome)}',
                    icon: Icons.work_outline,
                    iconColor: AppColors.secondary,
                    valueColor: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryFixed.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        size: 20,
                        color: AppColors.onTertiaryFixedVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Que Hacienda no te pille por sorpresa 💸 Tu hucha de '
                          '${hidden ? '••••' : euroInt(s.tax)} ya está apartada en la subcuenta.',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.onTertiaryFixed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.valueColor = AppColors.onSurface,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppText.labelSm.copyWith(color: AppColors.outline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.numericStat.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignsSection extends StatelessWidget {
  const _CampaignsSection({required this.finance});
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final list = finance.filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Campañas en curso',
          trailing: TextButton.icon(
            onPressed: () => finance.setFilter(
              finance.filter == null ? CampaignStatus.pending : null,
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.onTertiaryContainer,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Text(
              finance.filter == null ? 'Filtrar' : 'Ver todas',
              style: AppText.labelSm.copyWith(
                color: AppColors.onTertiaryContainer,
              ),
            ),
            label: const Icon(Icons.chevron_right, size: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final s in [
                CampaignStatus.pending,
                CampaignStatus.production,
                CampaignStatus.paid,
              ]) ...[
                PillChip(
                  label: switch (s) {
                    CampaignStatus.pending => 'Pendientes cobro',
                    CampaignStatus.production => 'En producción',
                    CampaignStatus.paid => 'Cobradas',
                  },
                  count: finance.countFor(s),
                  selected: finance.filter == s,
                  onTap: () => finance.setFilter(s),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (list.isEmpty)
          const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'Nada por aquí',
            subtitle: 'Registra una colaboración desde la pestaña Campaña.',
          )
        else
          for (final c in list) ...[
            _CampaignCard(campaign: c, finance: finance),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.finance});
  final Campaign campaign;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final hidden = finance.hideAmounts;
    String money(num v) => hidden ? '••••' : euroInt(v);

    void openDetail() => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampaignDetailScreen(campaignId: c.id!),
      ),
    );

    return SurfaceCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: openDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandAvatar(brand: c.brand),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.brand, style: AppText.titleSm),
                          Text(
                            finance.deliverableSummary(c.id!),
                            style: AppText.bodySm.copyWith(
                              color: AppColors.outline,
                            ),
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
                        Text(money(c.grossFee), style: AppText.headlineMd),
                        Text(
                          'FEE BRUTO',
                          style: AppText.labelSm.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Tag(
                      label: 'Neto: ${hidden ? '••••' : euroSigned(c.net)}',
                      bg: AppColors.secondaryContainer.withValues(alpha: 0.3),
                      fg: AppColors.onSecondaryContainer,
                      icon: Icons.payments_outlined,
                    ),
                    if (c.taxPct > 0)
                      Tag(
                        label:
                            'Hacienda: ${hidden ? '••••' : euroSigned(-c.taxCut)}',
                        bg: AppColors.errorContainer.withValues(alpha: 0.4),
                        fg: AppColors.onErrorContainer,
                      ),
                    if (c.agencyPct > 0)
                      Tag(
                        label:
                            'Agencia: ${hidden ? '••••' : euroSigned(-c.agencyCut)}',
                        bg: AppColors.tertiaryFixed.withValues(alpha: 0.6),
                        fg: AppColors.onTertiaryFixedVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: _CampaignFooter(campaign: c)),
                RoundIconButton(
                  icon: Icons.arrow_forward,
                  size: 28,
                  iconSize: 16,
                  bg: AppColors.surfaceContainerHighest,
                  fg: AppColors.onSurface,
                  onTap: openDetail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignFooter extends StatelessWidget {
  const _CampaignFooter({required this.campaign});
  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final style = AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant);
    switch (c.status) {
      case CampaignStatus.pending:
        final due = c.dueDate;
        final overdue = due != null && due.isBefore(DateTime.now());
        return Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: overdue ? AppColors.error : AppColors.outline,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: style,
                  children: [
                    TextSpan(text: 'Cobro a ${c.terms.label} · '),
                    TextSpan(
                      text: due == null ? 'Sin fecha' : dueLabel(due),
                      style: style.copyWith(
                        fontWeight: FontWeight.w600,
                        color: overdue ? AppColors.error : AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case CampaignStatus.production:
        final draft = c.draftDeadline;
        return Row(
          children: [
            const PulsingDot(color: AppColors.onTertiaryContainer),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                draft == null
                    ? 'En producción · sin fecha de draft'
                    : 'Draft: ${relativeDayLabel(draft)} · ${dueLabel(draft).replaceFirst('Vence', 'entrega')}',
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case CampaignStatus.paid:
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondaryFixedDim,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Cobrada · Facturada ${c.invoiceDate == null ? '' : shortDate(c.invoiceDate!)}',
              style: style,
            ),
          ],
        );
    }
  }
}

/// Avatar cuadrado con la inicial de la marca.
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({super.key, required this.brand, this.size = 44});
  final String brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = brand
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        initials,
        style: AppText.titleSm.copyWith(
          color: AppColors.secondaryFixed,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

class _ExpensesSection extends StatelessWidget {
  const _ExpensesSection({required this.finance});
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final items = finance.expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .take(6)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: 'Gastos deducibles',
          subtitle: 'Desgrava IVA para optimizar tu trimestre',
          trailing: RoundIconButton(
            icon: Icons.add,
            bg: AppColors.surfaceContainerHigh,
            fg: AppColors.onSurface,
            tooltip: 'Añadir gasto',
            onTap: () => showExpenseForm(context),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Sin gastos este mes',
            subtitle: 'Añade software, luz, fibra o atrezzo para deducir IVA.',
          )
        else
          SurfaceCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ExpenseRow(expense: items[i], finance: finance),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.finance});
  final Expense expense;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final hint = e.deductiblePct < 100
        ? 'IVA ${euro(e.recoverableVat)} · ${e.deductiblePct.round()}% deducible'
        : e.hasReceipt
        ? 'IVA ${euro(e.recoverableVat)} · Ticket guardado'
        : '100% deducible';

    return Dismissible(
      key: ValueKey('expense-${e.id}'),
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
        title: 'Eliminar gasto',
        message: '¿Quitar "${e.title}" de tus gastos deducibles?',
      ),
      onDismissed: (_) => finance.deleteExpense(e.id!),
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
              backgroundColor: AppColors.surfaceContainer,
              child: Icon(
                e.category.icon,
                size: 18,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: AppText.titleSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    e.description ?? e.category.label,
                    style: AppText.bodySm.copyWith(color: AppColors.outline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      finance.hideAmounts ? '••••' : euro(e.amount),
                      style: AppText.numericStat,
                    ),
                  ),
                  Text(
                    hint,
                    style: AppText.labelSm.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.finance});
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final s = finance.monthSummary;
    final pending = finance.countFor(CampaignStatus.pending);
    final text = pending > 0
        ? 'Tienes $pending ${pending == 1 ? 'factura pendiente' : 'facturas pendientes'} de cobro. '
              'Cuando entren, tu hucha fiscal sube a ${euroInt(s.tax)}. ¡Sin sustos trimestrales! 🎉'
        : 'Todo cobrado. Tu IVA recuperable este mes es ${euro(s.vatRecoverable)}. ¡El siguiente unboxing va sin estrés! 🎉';

    return SurfaceCard(
      color: AppColors.surfaceContainerHigh,
      elevated: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.tertiaryFixedDim, AppColors.secondaryFixed],
              ),
            ),
            child: const Icon(
              Icons.local_cafe_outlined,
              color: AppColors.onTertiaryFixed,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TIP DEL MES',
                  style: AppText.labelSm.copyWith(color: AppColors.outline),
                ),
                const SizedBox(height: 4),
                Text(text, style: AppText.bodySm.copyWith(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
