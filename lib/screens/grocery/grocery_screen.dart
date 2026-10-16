import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/grocery.dart';
import '../../providers/grocery_provider.dart';
import '../../widgets/common.dart';
import 'price_editor_sheet.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final _quickAdd = TextEditingController();

  @override
  void dispose() {
    _quickAdd.dispose();
    super.dispose();
  }

  Future<void> _add(GroceryProvider grocery) async {
    final name = _quickAdd.text.trim();
    if (name.isEmpty) return;
    final product = await grocery.quickAdd(name);
    _quickAdd.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    if (product.prices.isEmpty) {
      await showPriceEditor(context, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();
    if (!grocery.loaded) {
      return const Scaffold(
        appBar: AppHeader(section: 'Supermercado'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pending = grocery.cart.where((i) => !i.checked).length;

    return Scaffold(
      appBar: const AppHeader(section: 'Supermercado'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.margin,
          AppSpacing.sm,
          AppSpacing.margin,
          AppSpacing.xl,
        ),
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 20, color: AppColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'CESTA OPTIMIZADA',
                  style: AppText.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_checkout,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$pending ${pending == 1 ? 'ítem listo' : 'ítems listos'}',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _TotalCard(grocery: grocery),
          const SizedBox(height: AppSpacing.lg),
          SurfaceCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quickAdd,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _add(grocery),
                        decoration: InputDecoration(
                          hintText:
                              'Añadir ítem (ej. Leche almendras, matcha...)',
                          prefixIcon: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                          ),
                          fillColor: AppColors.surfaceContainer,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            borderSide: const BorderSide(
                              color: AppColors.secondaryFixedDim,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: FilledButton(
                        onPressed: () => _add(grocery),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Icon(Icons.add, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        'Super:',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      for (final s in grocery.supermarkets) ...[
                        PillChip(
                          label: s.name,
                          dense: true,
                          selected: grocery.selectedId == s.id,
                          unselectedColor: AppColors.surfaceContainer,
                          onTap: () => grocery.selectSupermarket(s.id!),
                        ),
                        const SizedBox(width: 6),
                      ],
                      PillChip(
                        label: '+',
                        dense: true,
                        unselectedColor: AppColors.surfaceContainer,
                        onTap: () => _addSupermarket(context, grocery),
                      ),
                    ],
                  ),
                ),
                if (grocery.products.length > grocery.cart.length) ...[
                  const SizedBox(height: 10),
                  _SuggestionRow(grocery: grocery),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Próxima compra', style: AppText.headlineMd),
                    Tag(
                      label: pending == 0 && grocery.cart.isNotEmpty
                          ? '¡Todo comprado!'
                          : '$pending de ${grocery.cart.length} pendientes',
                      bg: AppColors.surfaceContainerHighest,
                      fg: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (grocery.cart.any((i) => i.checked))
                PillChip(
                  label: 'Limpiar listos',
                  icon: Icons.clear_all,
                  dense: true,
                  unselectedColor: AppColors.surfaceContainer,
                  onTap: () async {
                    final n = await grocery.clearChecked();
                    if (context.mounted) {
                      showToast(
                        context,
                        'Cesta limpia',
                        subtitle:
                            '$n ${n == 1 ? 'ítem quitado' : 'ítems quitados'}',
                        emoji: '🧹',
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (grocery.cart.isEmpty)
            const EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Cesta vacía',
              subtitle:
                  'Añade productos para comparar precios entre supermercados.',
            )
          else
            for (final item in grocery.cart) ...[
              _CartItemCard(item: item, grocery: grocery),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: AppSpacing.sm),
          _ComparisonCard(grocery: grocery),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            color: AppColors.surfaceContainerLow,
            elevated: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  child: Icon(
                    Icons.edit_note,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTA DE DESPENSA',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pide factura simplificada si la compra entra como atrezzo culinario: '
                        'así la puedes añadir a gastos deducibles desde Finanzas.',
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
        ],
      ),
    );
  }

  Future<void> _addSupermarket(
    BuildContext context,
    GroceryProvider grocery,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Nuevo supermercado', style: AppText.headlineMd),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Ej. Alcampo'),
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
      await grocery.addSupermarket(name.trim());
    }
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.grocery});
  final GroceryProvider grocery;

  @override
  Widget build(BuildContext context) {
    final inCart = grocery.cart.map((i) => i.product.id).toSet();
    final suggestions = grocery.products
        .where((p) => !inCart.contains(p.id))
        .take(8)
        .toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'Histórico:',
              style: AppText.labelSm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(width: 6),
            for (final p in suggestions) ...[
              ActionChip(
                label: Text(p.name, style: AppText.labelSm),
                avatar: const Icon(Icons.history, size: 14),
                backgroundColor: AppColors.surfaceContainerLow,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                onPressed: () => grocery.addExistingProduct(p),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.grocery});
  final GroceryProvider grocery;

  @override
  Widget build(BuildContext context) {
    final quote = grocery.selectedQuote;
    final saving = grocery.basketSaving;
    final selected = grocery.selected;

    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL ESTIMADO ACTUAL',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          euro(quote?.total ?? 0),
                          style: AppText.headlineXlMobile,
                        ),
                        if (selected != null)
                          Tag(
                            label: 'en ${selected.name}',
                            bg: AppColors.secondaryContainer.withValues(
                              alpha: 0.4,
                            ),
                            fg: AppColors.onSecondaryContainer,
                          ),
                      ],
                    ),
                    if (quote != null && !quote.isComplete)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${quote.totalItems - quote.coveredItems} ${quote.totalItems - quote.coveredItems == 1 ? 'producto sin precio' : 'productos sin precio'} aquí',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.savings, color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: saving == null
                ? Text(
                    'Añade productos con precio en al menos dos supermercados para ver tu ahorro.',
                    style: AppText.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : saving.saving >= 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '¡Ahorras ${euro(saving.saving)} aquí!',
                              style: AppText.titleSm,
                            ),
                          ),
                          Tag(
                            label:
                                '-${saving.pct.toStringAsFixed(1).replaceAll('.', ',')}%',
                            bg: AppColors.secondaryFixed,
                            fg: AppColors.onSecondaryFixed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Respecto a hacer esta misma compra en ${saving.other.name}. '
                        'Para que el café de creador no te cueste un riñón ☕',
                        style: AppText.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Esta cesta sale ${euro(-saving.saving)} más cara aquí que en ${saving.other.name}.',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
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

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item, required this.grocery});
  final CartItem item;
  final GroceryProvider grocery;

  @override
  Widget build(BuildContext context) {
    final sel = grocery.selectedId;
    final selName = grocery.selected?.name ?? '';
    final unit = sel == null ? null : item.product.priceAt(sel);
    final total = sel == null ? null : item.totalAt(sel);
    final cmp = grocery.compare(item.product);
    final alt = unit == null ? grocery.alternativeFor(item.product) : null;

    final title = item.quantity > 1
        ? '${item.product.name} (x${item.quantity})'
        : item.product.name;

    Widget badge;
    if (unit == null) {
      badge = alt == null
          ? Tag(
              label: 'Sin precio · toca para añadir',
              bg: AppColors.surfaceContainer,
              fg: AppColors.outline,
            )
          : Tag(
              label:
                  'Solo en ${alt.name}: ${euro(item.product.priceAt(alt.id!)!)}',
              bg: AppColors.tertiaryFixed.withValues(alpha: 0.6),
              fg: AppColors.onTertiaryContainer,
            );
    } else if (cmp == null) {
      badge = Tag(
        label: 'Sin comparativa',
        bg: AppColors.surfaceContainer,
        fg: AppColors.outline,
      );
    } else if (cmp.difference.abs() < 0.01) {
      badge = Tag(
        label: 'Precio parejo',
        bg: AppColors.surfaceContainer,
        fg: AppColors.outline,
      );
    } else if (cmp.difference > 0) {
      badge = Tag(
        label:
            '+${euro(cmp.difference * item.quantity)} vs ${cmp.supermarket.name}',
        bg: AppColors.secondaryContainer.withValues(alpha: 0.4),
        fg: AppColors.onSecondaryContainer,
        icon: Icons.trending_down,
      );
    } else {
      badge = Tag(
        label:
            '${cmp.supermarket.name}: ${euro(item.product.priceAt(cmp.supermarket.id!)!)} (${euro(cmp.difference)})',
        bg: AppColors.surfaceContainerHigh,
        fg: AppColors.onSurfaceVariant,
      );
    }

    return Dismissible(
      key: ValueKey('cart-${item.id}'),
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
      onDismissed: (_) => grocery.removeItem(item),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: item.checked ? 0.6 : 1,
        child: SurfaceCard(
          onTap: () => showPriceEditor(context, item.product, cartItem: item),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => grocery.toggleChecked(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: item.checked
                        ? AppColors.secondaryFixedDim
                        : AppColors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: item.checked
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: AppColors.surface,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppText.titleSm.copyWith(
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.checked
                                  ? AppColors.outline
                                  : AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          total == null ? '-- €' : euro(total),
                          style: AppText.headlineMd,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          unit == null
                              ? '$selName · sin homólogo'
                              : '$selName · ${euro(unit)}/ud${item.product.note == null ? '' : ' · ${item.product.note}'}',
                          style: AppText.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        badge,
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.grocery});
  final GroceryProvider grocery;

  @override
  Widget build(BuildContext context) {
    final quotes = grocery.quotes;
    final items = grocery.cart.where((i) => !i.checked).length;
    final maxTotal = quotes.fold<double>(
      0,
      (m, q) => q.total > m ? q.total : m,
    );
    final winner = quotes.where((q) => q.isComplete).firstOrNull;

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
                    Text('Comparativa de Cesta', style: AppText.headlineMd),
                    Text(
                      items == 0
                          ? 'Añade productos para comparar'
                          : 'Mismos $items productos según dónde llenes el carro',
                      style: AppText.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.analytics_outlined, color: AppColors.outline),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < quotes.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _QuoteBar(
              quote: quotes[i],
              fraction: maxTotal == 0 ? 0 : quotes[i].total / maxTotal,
              isWinner: identical(quotes[i], winner),
              isWorst:
                  i == quotes.length - 1 &&
                  quotes.length > 1 &&
                  quotes[i].isComplete,
              selected: quotes[i].supermarket.id == grocery.selectedId,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteBar extends StatelessWidget {
  const _QuoteBar({
    required this.quote,
    required this.fraction,
    required this.isWinner,
    required this.isWorst,
    required this.selected,
  });

  final BasketQuote quote;
  final double fraction;
  final bool isWinner;
  final bool isWorst;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = isWinner
        ? AppColors.secondaryFixedDim
        : isWorst
        ? AppColors.error.withValues(alpha: 0.6)
        : AppColors.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    quote.supermarket.name,
                    style: AppText.bodySm.copyWith(
                      fontWeight: isWinner || selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                  if (isWinner)
                    Text(
                      '(Ganador)',
                      style: AppText.labelSm.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  if (!quote.isComplete)
                    Text(
                      '${quote.coveredItems}/${quote.totalItems} productos',
                      style: AppText.labelSm.copyWith(color: AppColors.outline),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              euro(quote.total),
              style: isWinner
                  ? AppText.numericStat.copyWith(color: AppColors.secondary)
                  : AppText.titleSm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            minHeight: 10,
            backgroundColor: AppColors.surfaceContainerHigh,
            color: color,
          ),
        ),
      ],
    );
  }
}
