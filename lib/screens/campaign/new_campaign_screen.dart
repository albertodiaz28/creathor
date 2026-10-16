import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/campaign.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common.dart';

class NewCampaignScreen extends StatefulWidget {
  const NewCampaignScreen({super.key, required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<NewCampaignScreen> createState() => _NewCampaignScreenState();
}

class _NewCampaignScreenState extends State<NewCampaignScreen> {
  final _brand = TextEditingController();
  final _title = TextEditingController();
  final _gross = TextEditingController(text: '4000');
  final _agencyName = TextEditingController();
  final _customDeliverable = TextEditingController();

  final Set<String> _selected = {'1x Reel IG', '3x Stories'};
  final List<String> _presets = List.of(kDeliverablePresets);
  double _agencyPct = 15;
  double _taxPct = kVatPct;
  PaymentTerms _terms = PaymentTerms.days30;
  DateTime? _draftDeadline;
  DateTime? _publishDate;
  bool _saving = false;

  static const _deliverableIcons = <String, IconData>{
    '1x Reel IG': Icons.videocam_outlined,
    '3x Stories': Icons.history_toggle_off,
    '1x TikTok': Icons.music_note_outlined,
    'Derechos 3 meses': Icons.copyright_outlined,
    'Post Carrusel': Icons.photo_camera_outlined,
    '1x YouTube Short': Icons.play_circle_outline,
  };

  @override
  void initState() {
    super.initState();
    _draftDeadline = DateTime.now().add(const Duration(days: 7, hours: 18));
    _gross.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _brand.dispose();
    _title.dispose();
    _gross.dispose();
    _agencyName.dispose();
    _customDeliverable.dispose();
    super.dispose();
  }

  double get _grossValue =>
      double.tryParse(_gross.text.replaceAll(',', '.')) ?? 0;
  double get _agencyCut => _grossValue * _agencyPct / 100;
  double get _taxCut => _grossValue * _taxPct / 100;
  double get _net =>
      (_grossValue - _agencyCut - _taxCut).clamp(0, double.infinity);
  double get _netPct => (100 - _agencyPct - _taxPct).clamp(0, 100);

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final base = initial ?? DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 18,
      time?.minute ?? 0,
    );
  }

  void _addCustomDeliverable() {
    final v = _customDeliverable.text.trim();
    if (v.isEmpty) return;
    setState(() {
      if (!_presets.contains(v)) _presets.add(v);
      _selected.add(v);
      _customDeliverable.clear();
    });
  }

  Future<void> _save() async {
    if (_brand.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el nombre de la marca')),
      );
      return;
    }
    if (_grossValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El fee bruto debe ser mayor que 0')),
      );
      return;
    }
    setState(() => _saving = true);
    final finance = context.read<FinanceProvider>();
    final deadlines = context.read<DeadlineProvider>();
    final brand = _brand.text.trim();
    final reminders = await finance.createCampaign(
      Campaign(
        brand: brand,
        title: _title.text.trim().isEmpty
            ? 'Colaboración con $brand'
            : _title.text.trim(),
        grossFee: _grossValue,
        agencyPct: _agencyPct,
        taxPct: _taxPct,
        terms: _terms,
        status: CampaignStatus.production,
        createdAt: DateTime.now(),
        draftDeadline: _draftDeadline,
        publishDate: _publishDate,
        agencyName: _agencyName.text.trim().isEmpty
            ? null
            : _agencyName.text.trim(),
      ),
      _presets.where(_selected.contains).toList(),
    );
    await deadlines.load();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _brand.clear();
      _title.clear();
      _agencyName.clear();
      _gross.text = '4000';
      _selected
        ..clear()
        ..addAll(['1x Reel IG', '3x Stories']);
      _draftDeadline = DateTime.now().add(const Duration(days: 7, hours: 18));
      _publishDate = null;
    });
    showToast(
      context,
      '¡Campaña guardada con éxito!',
      subtitle: reminders == 0
          ? 'Sin avisos de calendario'
          : 'Se ${reminders == 1 ? 'agregó 1 aviso' : 'agregaron $reminders avisos'} a tu calendario.',
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(section: 'Nueva Campaña'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.sm,
          AppSpacing.margin,
          AppSpacing.xl,
        ),
        children: [
          _IntroCard(),
          const SizedBox(height: AppSpacing.lg),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre de la Marca', style: AppText.labelLg),
                const SizedBox(height: 6),
                TextField(
                  controller: _brand,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Nike, Notion, Dyson...',
                    prefixIcon: Icon(Icons.verified_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la campaña (opcional)',
                    prefixIcon: Icon(Icons.campaign_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _GrossFeeField(controller: _gross),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Entregables Pactados',
                        style: AppText.labelLg,
                      ),
                    ),
                    Text(
                      'Toca para seleccionar',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in _presets)
                      PillChip(
                        label: d,
                        icon:
                            _deliverableIcons[d] ?? Icons.check_circle_outline,
                        selected: _selected.contains(d),
                        onTap: () => setState(() {
                          _selected.contains(d)
                              ? _selected.remove(d)
                              : _selected.add(d);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customDeliverable,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _addCustomDeliverable(),
                  decoration: InputDecoration(
                    hintText: 'Otro entregable (ej. 1x Unboxing)',
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _addCustomDeliverable,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SplitCard(
            net: _net,
            netPct: _netPct,
            agencyPct: _agencyPct,
            taxPct: _taxPct,
            agencyCut: _agencyCut,
            taxCut: _taxCut,
            onAgency: (v) => setState(() => _agencyPct = v),
            onTax: (v) => setState(() => _taxPct = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 22),
                    const SizedBox(width: 8),
                    Text('Condiciones & Calendario', style: AppText.titleSm),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'TÉRMINOS DE PAGO',
                  style: AppText.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final t in PaymentTerms.values) ...[
                      Expanded(
                        child: _TermButton(
                          terms: t,
                          selected: _terms == t,
                          onTap: () => setState(() => _terms = t),
                        ),
                      ),
                      if (t != PaymentTerms.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _agencyName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Agencia / manager (opcional)',
                    prefixIcon: Icon(Icons.handshake_outlined, size: 20),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DateField(
                  label: 'FECHA LÍMITE DEL PRIMER BORRADOR (DRAFT)',
                  icon: Icons.flag_outlined,
                  value: _draftDeadline,
                  onTap: () async {
                    final d = await _pickDateTime(_draftDeadline);
                    if (d != null) setState(() => _draftDeadline = d);
                  },
                  onClear: () => setState(() => _draftDeadline = null),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Se creará un deadline en tu calendario con la entrega del borrador.',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _DateField(
                  label: 'FECHA DE PUBLICACIÓN (OPCIONAL)',
                  icon: Icons.rocket_launch_outlined,
                  value: _publishDate,
                  onTap: () async {
                    final d = await _pickDateTime(
                      _publishDate ??
                          _draftDeadline?.add(const Duration(days: 7)),
                    );
                    if (d != null) setState(() => _publishDate = d);
                  },
                  onClear: () => setState(() => _publishDate = null),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: _saving ? 'Guardando…' : 'Guardar y Agendar Deadlines',
            icon: Icons.auto_awesome,
            height: 56,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Tus finanzas permanecen 100% privadas en tu dispositivo',
                style: AppText.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tag(
                  label: 'SPLIT INTELIGENTE',
                  bg: Color(0x3326E19A),
                  fg: AppColors.onSecondaryFixedVariant,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 6),
                Text('Nueva Colaboración 🤝', style: AppText.headlineXlMobile),
                Text(
                  'Calculamos lo que te queda limpio en un segundo y sin mareos.',
                  style: AppText.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(Icons.handshake_outlined, size: 28),
          ),
        ],
      ),
    );
  }
}

class _GrossFeeField extends StatelessWidget {
  const _GrossFeeField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'FEE BRUTO ACORDADO',
                  style: AppText.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const PulsingDot(color: AppColors.secondary, size: 6),
              const SizedBox(width: 4),
              Text(
                'Dinero Total',
                style: AppText.labelSm.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('€', style: AppText.headlineXl),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                  ],
                  style: AppText.headlineXl,
                  decoration: const InputDecoration(
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '0',
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Base imponible sin desglosar comisiones ni IVA.',
            style: AppText.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SplitCard extends StatelessWidget {
  const _SplitCard({
    required this.net,
    required this.netPct,
    required this.agencyPct,
    required this.taxPct,
    required this.agencyCut,
    required this.taxCut,
    required this.onAgency,
    required this.onTax,
  });

  final double net, netPct, agencyPct, taxPct, agencyCut, taxCut;
  final ValueChanged<double> onAgency;
  final ValueChanged<double> onTax;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedBar(
            height: 6,
            gap: 0,
            segments: [
              (netPct / 100, AppColors.secondaryFixedDim),
              (agencyPct / 100, AppColors.onTertiaryContainer),
              (taxPct / 100, AppColors.outlineVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Tag(
                        label: 'Limpio para ti 🚀',
                        bg: AppColors.secondaryFixed,
                        fg: AppColors.onSecondaryFixed,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              euroPlain(net),
                              key: ValueKey(net.round()),
                              style: AppText.headlineXl,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('€', style: AppText.titleSm),
                        ],
                      ),
                      Text(
                        'Listo para transferir a tu cuenta personal.',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryFixedDim.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    size: 32,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SliderRow(
            label: 'Comisión Agencia / Manager',
            dot: AppColors.onTertiaryContainer,
            activeColor: AppColors.onTertiaryContainer,
            value: agencyPct,
            max: 35,
            cut: agencyCut,
            onChanged: onAgency,
          ),
          const SizedBox(height: AppSpacing.md),
          _SliderRow(
            label: 'IVA / Hucha Fiscal',
            dot: AppColors.outline,
            activeColor: AppColors.primary,
            value: taxPct,
            max: 45,
            cut: taxCut,
            onChanged: onTax,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.dot,
    required this.activeColor,
    required this.value,
    required this.max,
    required this.cut,
    required this.onChanged,
  });

  final String label;
  final Color dot;
  final Color activeColor;
  final double value;
  final double max;
  final double cut;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: AppText.titleSm)),
              Text(
                '-${euroInt(cut)}',
                style: AppText.titleSm.copyWith(color: AppColors.error),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value,
                  min: 0,
                  max: max,
                  divisions: max.round(),
                  activeColor: activeColor,
                  onChanged: onChanged,
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  percent(value),
                  textAlign: TextAlign.right,
                  style: AppText.numericStat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TermButton extends StatelessWidget {
  const _TermButton({
    required this.terms,
    required this.selected,
    required this.onTap,
  });
  final PaymentTerms terms;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : AppColors.onSurface;
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      elevation: selected ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  terms.label,
                  style: AppText.labelLg.copyWith(color: fg),
                ),
              ),
              Text(
                terms.hint,
                style: AppText.labelSm.copyWith(
                  color: selected
                      ? AppColors.onPrimary.withValues(alpha: 0.8)
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final IconData icon;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              suffixIcon: value == null
                  ? const Icon(Icons.add, size: 18)
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onClear,
                    ),
            ),
            child: Text(
              value == null
                  ? 'Sin fecha'
                  : '${longDate(value!)} · ${timeOfDay(value!)}',
              style: AppText.bodyMd.copyWith(
                color: value == null ? AppColors.outline : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
