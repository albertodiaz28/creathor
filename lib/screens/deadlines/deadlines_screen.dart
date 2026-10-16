import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/deadline.dart';
import '../../providers/deadline_provider.dart';
import '../../widgets/common.dart';
import 'deadline_form_sheet.dart';

class DeadlinesScreen extends StatelessWidget {
  const DeadlinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DeadlineProvider>();
    if (!p.loaded) {
      return const Scaffold(
        appBar: AppHeader(section: 'Deadlines'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final visible = p.visible;

    return Scaffold(
      appBar: const AppHeader(section: 'Deadlines'),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: FloatingActionButton.extended(
          onPressed: () => showDeadlineForm(context),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: const StadiumBorder(),
          icon: const Icon(
            Icons.add_circle_outline,
            color: AppColors.secondaryFixed,
          ),
          label: Text(
            'Añadir Deadline',
            style: AppText.titleSm.copyWith(
              color: AppColors.onPrimary,
              fontSize: 15,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.sm,
          AppSpacing.margin,
          96,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Deadlines 📅', style: AppText.headlineXlMobile),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final v in CalendarView.values)
                      PillChip(
                        label: v == CalendarView.week ? 'Semana' : 'Mes',
                        dense: true,
                        selected: p.view == v,
                        unselectedColor: Colors.transparent,
                        onTap: () => p.setView(v),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Que no se te escape ningún entregable ni revisión ${p.view == CalendarView.week ? 'esta semana' : 'este mes'} ✨',
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PriorityCard(provider: p),
          const SizedBox(height: AppSpacing.lg),
          _WeekStrip(provider: p),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                PillChip(
                  label: 'Todos',
                  selected: p.typeFilter == null,
                  onTap: () => p.setTypeFilter(null),
                ),
                const SizedBox(width: 8),
                for (final t in DeadlineType.values) ...[
                  PillChip(
                    label: '${t.label} ${t.emoji}',
                    selected: p.typeFilter == t,
                    onTap: () => p.setTypeFilter(p.typeFilter == t ? null : t),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            EmptyState(
              icon: Icons.event_available_outlined,
              title: p.selectedDay == null
                  ? 'Sin entregas en este rango'
                  : 'Día libre de deadlines',
              subtitle:
                  'Añade un rodaje, entrega de draft o publicación con el botón inferior.',
            )
          else
            _Timeline(items: visible, provider: p),
        ],
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({required this.provider});
  final DeadlineProvider provider;

  @override
  Widget build(BuildContext context) {
    final awaiting = provider.awaitingApproval;
    if (awaiting.isEmpty) {
      return SurfaceCard(
        color: AppColors.surfaceContainerLow,
        elevated: false,
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sin borradores pendientes de validación. ¡Todo aprobado! 🙌',
                style: AppText.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final brands = awaiting.map((d) => d.brand ?? d.title).toSet().toList();
    final soonest = awaiting.reduce(
      (a, b) => a.dateTime.isBefore(b.dateTime) ? a : b,
    );
    final brandText = brands.length == 1
        ? brands.first
        : '${brands.take(brands.length - 1).join(', ')} y ${brands.last}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.onTertiaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt,
              color: AppColors.secondaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PRIORIDAD DE GUIÓN',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const PulsingDot(color: AppColors.secondaryFixed, size: 6),
                  ],
                ),
                Text(
                  '${awaiting.length} ${awaiting.length == 1 ? 'campaña pendiente' : 'campañas pendientes'} de aprobación',
                  style: AppText.titleSm.copyWith(color: AppColors.onTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$brandText ${brands.length == 1 ? 'espera' : 'esperan'} visto bueno antes del ${relativeDayLabel(soonest.dateTime).toLowerCase()}',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.tertiaryFixedDim,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.arrow_forward,
            bg: AppColors.surfaceContainerLowest.withValues(alpha: 0.15),
            fg: AppColors.onTertiary,
            onTap: () {
              provider.setTypeFilter(DeadlineType.draft);
              provider.selectDay(null);
            },
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.provider});
  final DeadlineProvider provider;

  @override
  Widget build(BuildContext context) {
    final p = provider;
    final today = dateOnly(DateTime.now());
    final label = p.view == CalendarView.week
        ? '${shortDate(p.weekStart)} – ${shortDate(p.weekStart.add(const Duration(days: 6)))}'
        : monthYear(p.anchor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RoundIconButton(
              icon: Icons.chevron_left,
              size: 28,
              onTap: () => p.shift(-1),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: GestureDetector(
                onTap: p.goToday,
                child: Text(
                  label.toUpperCase(),
                  style: AppText.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 6),
            RoundIconButton(
              icon: Icons.chevron_right,
              size: 28,
              onTap: () => p.shift(1),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.bolt, size: 14, color: AppColors.secondary),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                '${p.keyDeliveriesInRange} entregas clave',
                style: AppText.labelSm.copyWith(color: AppColors.secondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: p.stripDays.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = p.stripDays[i];
              final events = p.onDay(day);
              final isToday = isSameDay(day, today);
              final selected =
                  p.selectedDay != null && isSameDay(day, p.selectedDay!);
              final highlight = selected || (p.selectedDay == null && isToday);
              final fg = highlight ? AppColors.onPrimary : AppColors.onSurface;
              return Material(
                color: highlight
                    ? AppColors.primary
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                elevation: highlight ? 3 : 1,
                shadowColor: Colors.black26,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  onTap: () => p.selectDay(day),
                  child: SizedBox(
                    width: 52,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdayShort(day).toUpperCase(),
                          style: AppText.labelSm.copyWith(
                            color: highlight
                                ? AppColors.onPrimary.withValues(alpha: 0.75)
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: AppText.headlineMd.copyWith(
                            color: fg,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final t in DeadlineType.values)
                              if (events.any((e) => e.type == t && !e.done))
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        events.any(
                                              (e) => e.type == t && e.isUrgent,
                                            ) &&
                                            t == DeadlineType.draft
                                        ? AppColors.error
                                        : highlight
                                        ? AppColors.secondaryFixed
                                        : t.dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            if (events.every((e) => e.done))
                              const SizedBox(height: 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items, required this.provider});
  final List<Deadline> items;
  final DeadlineProvider provider;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 15,
          top: 16,
          bottom: 16,
          child: Container(width: 2, color: AppColors.surfaceContainerHighest),
        ),
        Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              _TimelineItem(deadline: items[i], provider: provider),
            ],
          ],
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.deadline, required this.provider});
  final Deadline deadline;
  final DeadlineProvider provider;

  @override
  Widget build(BuildContext context) {
    final d = deadline;
    final urgent = d.isUrgent && d.type == DeadlineType.draft;
    final overdue = d.isOverdue;

    final (nodeBg, nodeFg) = d.done
        ? (AppColors.secondaryContainer, AppColors.secondary)
        : urgent || overdue
        ? (AppColors.errorContainer, AppColors.error)
        : switch (d.type) {
            DeadlineType.shoot => (
              AppColors.secondaryContainer,
              AppColors.secondary,
            ),
            DeadlineType.draft => (
              AppColors.tertiaryFixed,
              AppColors.onTertiaryContainer,
            ),
            DeadlineType.publish => (
              AppColors.secondaryFixed,
              AppColors.secondary,
            ),
          };

    final when = d.allDay
        ? '${relativeDayLabel(d.dateTime)} • Todo el día'
        : '${relativeDayLabel(d.dateTime)} • ${timeOfDay(d.dateTime)}';

    final stripe = d.done
        ? null
        : urgent || overdue
        ? AppColors.errorContainer
        : d.type == DeadlineType.publish
        ? AppColors.secondaryFixedDim
        : null;

    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -32,
            top: 14,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: nodeBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 3),
              ),
              child: Center(
                child: d.done
                    ? Icon(Icons.check, size: 9, color: nodeFg)
                    : d.type == DeadlineType.shoot && !urgent
                    ? PulsingDot(color: nodeFg, size: 7)
                    : Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: nodeFg,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          ),
          SurfaceCard(
            padding: EdgeInsets.zero,
            clip: true,
            onTap: () => showDeadlineForm(context, existing: d),
            child: Opacity(
              opacity: d.done ? 0.65 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: stripe == null ? AppSpacing.md : AppSpacing.md + 4,
                      right: AppSpacing.md,
                      top: AppSpacing.md,
                      bottom: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Tag(
                              label: when,
                              uppercase: true,
                              bg: urgent || overdue
                                  ? AppColors.errorContainer
                                  : d.type.chipBg,
                              fg: urgent || overdue
                                  ? AppColors.onErrorContainer
                                  : d.type.chipFg,
                            ),
                            if (overdue && !d.done)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 13,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Vencido',
                                    style: AppText.labelSm.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              )
                            else if (urgent)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    size: 13,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Urgente',
                                    style: AppText.labelSm.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              )
                            else if (d.type == DeadlineType.publish && !d.done)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.trending_up,
                                    size: 13,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Hora punta',
                                    style: AppText.labelSm.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            Tag(
                              label: d.awaitingApproval
                                  ? 'Revisión Marca'
                                  : d.type.label,
                              icon: d.type.icon,
                              bg: d.awaitingApproval
                                  ? AppColors.errorContainer.withValues(
                                      alpha: 0.6,
                                    )
                                  : AppColors.surfaceContainer,
                              fg: d.awaitingApproval
                                  ? AppColors.onErrorContainer
                                  : AppColors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.title,
                                    style: AppText.titleSm.copyWith(
                                      decoration: d.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  if (d.description != null)
                                    Text(
                                      d.description!,
                                      style: AppText.bodySm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  if (d.brand != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        d.brand!.toUpperCase(),
                                        style: AppText.labelSm.copyWith(
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: d.done,
                              onChanged: (_) => provider.toggleDone(d),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (d.tasks.isNotEmpty || d.awaitingApproval)
                    Container(
                      color: AppColors.surfaceContainerLow.withValues(
                        alpha: 0.6,
                      ),
                      padding: EdgeInsets.only(
                        left: stripe == null
                            ? AppSpacing.md
                            : AppSpacing.md + 4,
                        right: AppSpacing.md,
                        top: 6,
                        bottom: 6,
                      ),
                      child: Column(
                        children: [
                          for (final t in d.tasks)
                            InkWell(
                              onTap: () => provider.toggleTask(t),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 28,
                                    child: Checkbox(
                                      value: t.done,
                                      onChanged: (_) => provider.toggleTask(t),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      t.label,
                                      style: AppText.bodySm.copyWith(
                                        decoration: t.done
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: t.done
                                            ? AppColors.outline
                                            : AppColors.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              if (d.tasks.isNotEmpty) ...[
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${d.tasksDone}/${d.tasks.length} ${d.tasks.length == 1 ? 'tarea lista' : 'tareas listas'}',
                                    style: AppText.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (d.awaitingApproval)
                                Flexible(
                                  child: Text(
                                    'Espera marca / agencia',
                                    style: AppText.labelSm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else if (d.tasks.isNotEmpty &&
                                  d.tasksDone < d.tasks.length &&
                                  !d.done)
                                Text(
                                  'En proceso',
                                  style: AppText.labelSm.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (stripe != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: stripe,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.xl),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
