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

/// Hoja "Nuevo compromiso" para crear o editar un deadline.
Future<void> showDeadlineForm(BuildContext context, {Deadline? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DeadlineForm(existing: existing),
  );
}

class _DeadlineForm extends StatefulWidget {
  const _DeadlineForm({this.existing});
  final Deadline? existing;

  @override
  State<_DeadlineForm> createState() => _DeadlineFormState();
}

class _DeadlineFormState extends State<_DeadlineForm> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  final _task = TextEditingController();
  late DeadlineType _type;
  late DateTime _dateTime;
  late bool _allDay;
  late bool _awaiting;
  int? _campaignId;
  final List<String> _newTasks = [];

  Deadline? get _existing => widget.existing;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _type = e?.type ?? DeadlineType.shoot;
    _dateTime =
        e?.dateTime ??
        DateTime.now()
            .add(const Duration(days: 1))
            .copyWith(hour: 17, minute: 0);
    _allDay = e?.allDay ?? false;
    _awaiting = e?.awaitingApproval ?? false;
    _campaignId = e?.campaignId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _task.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null) return;
    setState(
      () => _dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _dateTime.hour,
        _dateTime.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (t == null) return;
    setState(
      () => _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        t.hour,
        t.minute,
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pon un título al compromiso')),
      );
      return;
    }
    final p = context.read<DeadlineProvider>();
    final draft = Deadline(
      id: _existing?.id,
      campaignId: _campaignId,
      title: title,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      type: _type,
      dateTime: _dateTime,
      allDay: _allDay,
      done: _existing?.done ?? false,
      awaitingApproval: _type == DeadlineType.draft && _awaiting,
    );
    if (_existing == null) {
      await p.add(draft, tasks: _newTasks);
    } else {
      await p.update(draft);
      for (final t in _newTasks) {
        await p.addTask(_existing!.id!, t);
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    showToast(
      context,
      _existing == null ? 'Guardado en calendario' : 'Deadline actualizado',
      subtitle: '${_type.label} · ${relativeDayLabel(_dateTime)}',
      emoji: _type.emoji,
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = context.watch<FinanceProvider>().campaigns;
    final p = context.read<DeadlineProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.margin,
        right: AppSpacing.margin,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _existing == null
                        ? 'Nuevo Compromiso'
                        : 'Editar compromiso',
                    style: AppText.headlineMd,
                  ),
                ),
                if (_existing != null)
                  RoundIconButton(
                    icon: Icons.delete_outline,
                    fg: AppColors.error,
                    tooltip: 'Eliminar',
                    onTap: () async {
                      final ok = await confirmDialog(
                        context,
                        title: 'Eliminar deadline',
                        message:
                            '¿Quitar "${_existing!.title}" del calendario?',
                      );
                      if (!ok || !context.mounted) return;
                      await p.delete(_existing!.id!);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'CAMPAÑA / MARCA',
              style: AppText.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              initialValue: _campaignId,
              decoration: const InputDecoration(isDense: true),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Sin campaña vinculada'),
                ),
                for (final c in campaigns.where(
                  (c) => c.status != CampaignStatus.paid || c.id == _campaignId,
                ))
                  DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(
                      '${c.brand} · ${c.title}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() {
                _campaignId = v;
                if (_title.text.trim().isEmpty && v != null) {
                  final c = campaigns.firstWhere((c) => c.id == v);
                  _title.text = '${_type.label} ${c.brand}';
                }
              }),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Ej. RedBull Reel Aventura',
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Detalles (equipo, links, subtítulos…)',
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'TIPO',
              style: AppText.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in DeadlineType.values)
                  PillChip(
                    label: '${t.label} ${t.emoji}',
                    selected: _type == t,
                    onTap: () => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'FECHA & HORA',
              style: AppText.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.event_outlined, size: 20),
                      ),
                      child: Text(
                        longDate(_dateTime),
                        style: AppText.bodyMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: _allDay ? null : _pickTime,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        isDense: true,
                        prefixIcon: Icon(Icons.schedule, size: 20),
                      ),
                      child: Text(
                        _allDay ? 'Todo el día' : timeOfDay(_dateTime),
                        style: AppText.bodyMd.copyWith(
                          color: _allDay
                              ? AppColors.outline
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _allDay,
              activeThumbColor: AppColors.secondary,
              title: Text('Todo el día', style: AppText.bodyMd),
              onChanged: (v) => setState(() => _allDay = v),
            ),
            if (_type == DeadlineType.draft)
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _awaiting,
                activeThumbColor: AppColors.secondary,
                title: Text(
                  'Borrador pendiente de validación',
                  style: AppText.bodyMd,
                ),
                subtitle: Text(
                  'Aparece en la alerta de prioridades',
                  style: AppText.bodySm.copyWith(color: AppColors.outline),
                ),
                onChanged: (v) => setState(() => _awaiting = v),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'CHECKLIST',
              style: AppText.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            if (_existing != null)
              for (final t in _existing!.tasks)
                Row(
                  children: [
                    Icon(
                      t.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: t.done ? AppColors.secondary : AppColors.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.label, style: AppText.bodySm)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await p.deleteTask(t.id!);
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ],
                ),
            for (final t in _newTasks)
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_unchecked,
                    size: 18,
                    color: AppColors.outline,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: AppText.bodySm)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => _newTasks.remove(t)),
                  ),
                ],
              ),
            TextField(
              controller: _task,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _addTask(),
              decoration: InputDecoration(
                hintText: 'Ej. Cargar baterías, ajustar subtítulos…',
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addTask,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: _existing == null
                  ? 'Guardar en Calendario'
                  : 'Guardar cambios',
              icon: Icons.check,
              iconColor: AppColors.secondaryFixed,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    final v = _task.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _newTasks.add(v);
      _task.clear();
    });
  }
}
