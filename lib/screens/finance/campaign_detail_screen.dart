import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/campaign.dart';
import '../../models/deadline.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common.dart';

class CampaignDetailScreen extends StatelessWidget {
  const CampaignDetailScreen({super.key, required this.campaignId});

  final int campaignId;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final deadlines = context.watch<DeadlineProvider>();
    final campaign = finance.campaigns.cast<Campaign?>().firstWhere(
      (c) => c!.id == campaignId,
      orElse: () => null,
    );

    if (campaign == null) {
      return const Scaffold(
        appBar: AppHeader(section: 'Finanzas'),
        body: Center(child: Text('Campaña no encontrada')),
      );
    }

    final c = campaign;
    final deliverables = finance.deliverablesOf(c.id!);
    final done = deliverables.where((d) => d.status.isDone).length;
    final progress = deliverables.isEmpty ? 0.0 : done / deliverables.length;
    final linked = deadlines.all.where((d) => d.campaignId == c.id).toList();

    return Scaffold(
      appBar: const AppHeader(section: 'Finanzas'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.md,
          AppSpacing.margin,
          AppSpacing.xl,
        ),
        children: [
          Row(
            children: [
              RoundIconButton(
                icon: Icons.arrow_back,
                size: 40,
                iconSize: 20,
                bg: AppColors.surfaceContainer,
                fg: AppColors.onSurface,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              RoundIconButton(
                icon: Icons.delete_outline,
                size: 40,
                iconSize: 19,
                bg: AppColors.surfaceContainer,
                fg: AppColors.onSurface,
                tooltip: 'Eliminar campaña',
                onTap: () async {
                  final ok = await confirmDialog(
                    context,
                    title: 'Eliminar campaña',
                    message:
                        'Se borrarán sus entregables y se desvincularán sus deadlines.',
                  );
                  if (!ok || !context.mounted) return;
                  await finance.deleteCampaign(c.id!);
                  await deadlines.load();
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.graphic_eq,
                        size: 14,
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(c.brand.toUpperCase(), style: AppText.labelSm),
                  ],
                ),
              ),
              _StatusPill(campaign: c),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(c.title, style: AppText.headlineXlMobile),
          const SizedBox(height: 4),
          Text(
            'ID: #KRT-${c.createdAt.year}-${c.id.toString().padLeft(3, '0')}'
            '${c.agencyName == null ? '' : '  •  Vía ${c.agencyName}'}',
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FinancialCard(campaign: c, finance: finance),
          const SizedBox(height: AppSpacing.lg),
          SectionTitle(
            title: 'Entregables y Contenido',
            subtitle: '$done de ${deliverables.length} elementos cerrados',
            trailing: Tag(
              label: '${(progress * 100).round()}% Listo',
              bg: AppColors.secondaryContainer,
              fg: AppColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Toca un entregable para avanzar su estado',
            style: AppText.bodySm.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final d in deliverables) ...[
            _DeliverableTile(deliverable: d, finance: finance),
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: () => _addDeliverable(context, finance, c.id!),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.outlineVariant),
              shape: const StadiumBorder(),
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.add_task, size: 18),
            label: const Text('Añadir entregable'),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Hoja de Ruta de la Campaña', style: AppText.headlineMd),
          const SizedBox(height: AppSpacing.sm),
          _Roadmap(campaign: c, linked: linked),
          if (c.contactName != null || c.note != null) ...[
            const SizedBox(height: AppSpacing.lg),
            if (c.contactName != null)
              SurfaceCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.contactName!, style: AppText.titleSm),
                          if (c.contactRole != null)
                            Text(
                              c.contactRole!,
                              style: AppText.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (c.note != null) ...[
              const SizedBox(height: 10),
              SurfaceCard(
                color: AppColors.surfaceContainerLow,
                elevated: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      size: 20,
                      color: AppColors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOTA PERSONAL DE NEGOCIACIÓN',
                            style: AppText.labelSm,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${c.note}"',
                            style: AppText.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _addDeliverable(
    BuildContext context,
    FinanceProvider finance,
    int campaignId,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nuevo entregable', style: AppText.headlineMd),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. 2x Stories Q&A'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await finance.addDeliverable(campaignId, name.trim());
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.campaign});
  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final (label, bg, fg) = switch (c.status) {
      CampaignStatus.pending => (
        c.dueDate == null
            ? 'Pendiente de cobro'
            : dueLabel(c.dueDate!).replaceFirst('Vence', 'Cobro'),
        AppColors.secondaryContainer.withValues(alpha: 0.4),
        AppColors.onSecondaryContainer,
      ),
      CampaignStatus.production => (
        'En producción',
        AppColors.tertiaryFixed,
        AppColors.onTertiaryFixedVariant,
      ),
      CampaignStatus.paid => (
        'Cobrada ✓',
        AppColors.secondary,
        AppColors.onSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.status != CampaignStatus.paid) ...[
            PulsingDot(color: fg),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppText.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  const _FinancialCard({required this.campaign, required this.finance});
  final Campaign campaign;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final hidden = finance.hideAmounts;
    String m(num v) => hidden ? '••••' : euroInt(v);

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HONORARIOS TOTALES (BRUTO)',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(m(c.grossFee), style: AppText.headlineXl),
                        ),
                        Text(
                          'Base imponible',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedBar(
            height: 12,
            gap: 0,
            segments: [
              (c.netPct / 100, AppColors.secondaryContainer),
              (c.taxPct / 100, AppColors.errorContainer),
              (c.agencyPct / 100, AppColors.tertiaryFixed),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                'Bolsillo ${percent(c.netPct)}',
                style: AppText.labelSm.copyWith(
                  color: AppColors.onSecondaryContainer,
                ),
              ),
              Text(
                'IVA ${percent(c.taxPct)}',
                style: AppText.labelSm.copyWith(
                  color: AppColors.onErrorContainer,
                ),
              ),
              Text(
                'Agencia ${percent(c.agencyPct)}',
                style: AppText.labelSm.copyWith(
                  color: AppColors.onTertiaryFixedVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _LedgerRow(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: AppColors.secondaryContainer.withValues(alpha: 0.6),
            iconFg: AppColors.secondary,
            title: 'Limpio para ti',
            subtitle: 'Directo a tu cuenta corriente',
            value: hidden ? '••••' : euroSigned(c.net),
            valueColor: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          _LedgerRow(
            icon: Icons.account_balance_outlined,
            iconBg: AppColors.errorContainer.withValues(alpha: 0.6),
            iconFg: AppColors.error,
            title: 'Hucha IVA / Hacienda',
            subtitle: 'Retención auto-apartada (${percent(c.taxPct)})',
            value: hidden ? '••••' : euroSigned(-c.taxCut),
            valueColor: AppColors.error,
          ),
          const SizedBox(height: 8),
          _LedgerRow(
            icon: Icons.handshake_outlined,
            iconBg: AppColors.tertiaryFixed.withValues(alpha: 0.6),
            iconFg: AppColors.onTertiaryFixedVariant,
            title: c.agencyName ?? 'Comisión agencia',
            subtitle: 'Fee gestión y negociación (${percent(c.agencyPct)})',
            value: hidden ? '••••' : euroSigned(-c.agencyCut),
            valueColor: AppColors.onTertiaryFixedVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.invoiceDate == null
                        ? 'Sin facturar · Términos: ${c.terms.label} (${c.terms.hint})'
                        : 'Factura emitida: ${shortDate(c.invoiceDate!)} • Vencimiento ${c.terms.label}'
                              '${c.dueDate == null ? '' : ' (${shortDate(c.dueDate!)})'}',
                    style: AppText.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatusActions(campaign: c, finance: finance),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.campaign, required this.finance});
  final Campaign campaign;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return switch (c.status) {
      CampaignStatus.production => PrimaryButton(
        label: 'Marcar facturada',
        icon: Icons.receipt_long_outlined,
        height: 44,
        bg: AppColors.surfaceContainer,
        fg: AppColors.onSurface,
        onPressed: () => finance.setStatus(c, CampaignStatus.pending),
      ),
      CampaignStatus.pending => Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'A producción',
              icon: Icons.undo,
              height: 44,
              bg: AppColors.surfaceContainer,
              fg: AppColors.onSurface,
              onPressed: () => finance.setStatus(c, CampaignStatus.production),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PrimaryButton(
              label: 'Marcar cobrada',
              icon: Icons.check_circle,
              height: 44,
              bg: AppColors.secondaryContainer,
              fg: AppColors.onSecondaryContainer,
              onPressed: () {
                finance.setStatus(c, CampaignStatus.paid);
                showToast(
                  context,
                  '¡Cobrada con éxito!',
                  subtitle: 'Tu hucha fiscal ya está apartada',
                  emoji: '💸',
                );
              },
            ),
          ),
        ],
      ),
      CampaignStatus.paid => PrimaryButton(
        label: '¡Cobrada con éxito!',
        icon: Icons.check_circle,
        height: 44,
        bg: AppColors.secondary,
        fg: AppColors.onSecondary,
        onPressed: () => finance.setStatus(c, CampaignStatus.pending),
      ),
    };
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: iconBg,
            child: Icon(icon, size: 18, color: iconFg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.titleSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(value, style: AppText.numericStat.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

class _DeliverableTile extends StatelessWidget {
  const _DeliverableTile({required this.deliverable, required this.finance});
  final Deliverable deliverable;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final d = deliverable;
    final (icon, bg, fg) = switch (d.status) {
      DeliverableStatus.pending => (
        Icons.schedule,
        AppColors.tertiaryFixed,
        AppColors.onTertiaryFixedVariant,
      ),
      DeliverableStatus.draft => (
        Icons.edit_note,
        AppColors.surfaceContainerHigh,
        AppColors.onSurfaceVariant,
      ),
      DeliverableStatus.approved => (
        Icons.check,
        AppColors.secondaryContainer,
        AppColors.onSecondaryContainer,
      ),
      DeliverableStatus.published => (
        Icons.rocket_launch_outlined,
        AppColors.secondary,
        AppColors.onSecondary,
      ),
    };

    return Dismissible(
      key: ValueKey('deliverable-${d.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) => confirmDialog(
        context,
        title: 'Eliminar entregable',
        message: '¿Quitar "${d.name}"?',
      ),
      onDismissed: (_) => finance.deleteDeliverable(d.id!),
      child: SurfaceCard(
        onTap: () => finance.cycleDeliverable(d),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: bg,
              child: Icon(icon, size: 16, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(d.name, style: AppText.titleSm)),
                      Tag(
                        label: d.status.label,
                        bg: AppColors.surfaceContainer,
                        fg: d.status.isDone
                            ? AppColors.secondary
                            : AppColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                  if (d.note != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      d.note!,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Roadmap extends StatelessWidget {
  const _Roadmap({required this.campaign, required this.linked});
  final Campaign campaign;
  final List<Deadline> linked;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final now = DateTime.now();
    final steps = <(String, String?, DateTime, bool, IconData)>[
      (
        'Firma & Briefing recibido',
        'Campaña registrada en Kreator.',
        c.createdAt,
        true,
        Icons.done,
      ),
      for (final d in linked)
        (
          d.title,
          d.description,
          d.dateTime,
          d.done,
          d.done ? Icons.done : d.type.icon,
        ),
      if (c.invoiceDate != null)
        (
          'Factura emitida',
          'Términos: ${c.terms.label}.',
          c.invoiceDate!,
          true,
          Icons.done,
        ),
      if (c.dueDate != null)
        (
          'Transferencia bancaria',
          'Cobro en tu cuenta IBAN principal.',
          c.dueDate!,
          c.status == CampaignStatus.paid,
          c.status == CampaignStatus.paid
              ? Icons.done
              : Icons.account_balance_outlined,
        ),
    ]..sort((a, b) => a.$3.compareTo(b.$3));

    return SurfaceCard(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: steps[i].$4
                      ? AppColors.secondaryContainer
                      : AppColors.surfaceContainer,
                  child: Icon(
                    steps[i].$5,
                    size: 15,
                    color: steps[i].$4
                        ? AppColors.onSecondaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              steps[i].$1,
                              style: AppText.titleSm.copyWith(
                                fontWeight: steps[i].$4
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            shortDate(steps[i].$3),
                            style: AppText.labelSm.copyWith(
                              color: !steps[i].$4 && steps[i].$3.isAfter(now)
                                  ? AppColors.secondary
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (steps[i].$2 != null)
                        Text(
                          steps[i].$2!,
                          style: AppText.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
