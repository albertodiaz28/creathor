import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Cabecera fija: logo "Kreator" + subtítulo de sección + chip "Creando".
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, required this.section});

  final String section;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.margin),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.secondaryFixed,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kreator', style: AppText.headlineMd),
                    Text(
                      section.toUpperCase(),
                      style: AppText.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const _LivePill(label: 'Creando'),
                const SizedBox(width: AppSpacing.sm),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulsingDot(color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.labelSm.copyWith(
              color: AppColors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto que late (equivalente a `animate-pulse`).
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.35).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Tarjeta blanca con sombra suave (surface-container-lowest + shadow-sm).
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color = AppColors.surfaceContainerLowest,
    this.elevated = true,
    this.onTap,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool elevated;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

/// Cápsula seleccionable (filtros, supermercados, entregables).
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
    this.count,
    this.dense = false,
    this.selectedColor = AppColors.primary,
    this.unselectedColor = AppColors.surfaceContainerHigh,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final int? count;
  final bool dense;
  final Color selectedColor;
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    return Material(
      color: selected ? selectedColor : unselectedColor,
      borderRadius: BorderRadius.circular(AppRadius.full),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 4 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(label, style: AppText.labelSm.copyWith(color: fg)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.onPrimary.withValues(alpha: 0.2)
                        : AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.onPrimary
                          : AppColors.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta pequeña con fondo (badge de estado).
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.uppercase = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              uppercase ? label.toUpperCase() : label,
              style: AppText.labelSm.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra horizontal segmentada (neto / impuestos / agencia / gastos).
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    super.key,
    required this.segments,
    this.height = 10,
    this.gap = 2,
    this.background = AppColors.surfaceContainer,
  });

  /// Pares (fracción 0..1, color). Las fracciones deberían sumar <= 1.
  final List<(double, Color)> segments;
  final double height;
  final double gap;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.$1 > 0.001).toList();
    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              flex: (visible[i].$1 * 1000).round().clamp(1, 1000),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: visible[i].$2,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ],
          if (visible.isEmpty) const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppText.labelSm.copyWith(color: AppColors.outline)),
      ],
    );
  }
}

/// Botón circular de icono sobre fondo neutro.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 32,
    this.iconSize = 18,
    this.bg = AppColors.surfaceContainerHigh,
    this.fg = AppColors.onSurfaceVariant,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color bg;
  final Color fg;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

/// Botón principal negro redondeado (CTA).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = true,
    this.bg = AppColors.primary,
    this.fg = AppColors.onPrimary,
    this.iconColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expanded;
  final Color bg;
  final Color fg;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor ?? fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppText.titleSm.copyWith(color: fg)),
          ),
        ),
      ],
    );
    return SizedBox(
      height: height,
      width: expanded ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.surfaceContainerHighest,
          elevation: 2,
          shadowColor: Colors.black38,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: const StadiumBorder(),
        ),
        child: child,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.headlineMd),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppText.bodySm.copyWith(color: AppColors.outline),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.surfaceContainerLow,
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.outline),
          const SizedBox(height: 8),
          Text(title, style: AppText.titleSm, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppText.bodySm.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Muestra un aviso estilo toast oscuro (inverse-surface) en la parte inferior.
void showToast(
  BuildContext context,
  String title, {
  String? subtitle,
  String emoji = '✨',
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.secondaryFixed,
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.titleSm.copyWith(
                      color: AppColors.inverseOnSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: AppText.bodySm.copyWith(
                        color: AppColors.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

/// Diálogo de confirmación simple. Devuelve true si se confirma.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppText.headlineMd),
      content: Text(message, style: AppText.bodyMd),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.error : AppColors.primary,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
