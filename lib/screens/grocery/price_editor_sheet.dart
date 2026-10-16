import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/grocery.dart';
import '../../providers/grocery_provider.dart';
import '../../widgets/common.dart';

/// Hoja para editar precio por supermercado y cantidad de un producto.
Future<void> showPriceEditor(
  BuildContext context,
  Product product, {
  CartItem? cartItem,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PriceEditor(product: product, cartItem: cartItem),
  );
}

class _PriceEditor extends StatefulWidget {
  const _PriceEditor({required this.product, this.cartItem});
  final Product product;
  final CartItem? cartItem;

  @override
  State<_PriceEditor> createState() => _PriceEditorState();
}

class _PriceEditorState extends State<_PriceEditor> {
  late final Map<int, TextEditingController> _controllers;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    final grocery = context.read<GroceryProvider>();
    _controllers = {
      for (final s in grocery.supermarkets)
        s.id!: TextEditingController(
          text:
              widget.product
                  .priceAt(s.id!)
                  ?.toStringAsFixed(2)
                  .replaceAll('.', ',') ??
              '',
        ),
    };
    _quantity = widget.cartItem?.quantity ?? 1;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final grocery = context.read<GroceryProvider>();
    final prices = <int, double?>{
      for (final e in _controllers.entries)
        e.key: double.tryParse(e.value.text.replaceAll(',', '.').trim()),
    };
    await grocery.savePrices(widget.product, prices);
    if (widget.cartItem != null && _quantity != widget.cartItem!.quantity) {
      await grocery.setQuantity(widget.cartItem!, _quantity);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final grocery = context.watch<GroceryProvider>();
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
            Text(widget.product.name, style: AppText.headlineMd),
            Text(
              'Precio por unidad en cada supermercado. Deja vacío si no lo venden.',
              style: AppText.bodySm.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final s in grocery.supermarkets) ...[
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(s.name, style: AppText.titleSm),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controllers[s.id],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: '--',
                        suffixText: '€',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (widget.cartItem != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text('Cantidad en la cesta', style: AppText.titleSm),
                  ),
                  RoundIconButton(
                    icon: Icons.remove,
                    onTap: () => setState(
                      () => _quantity = (_quantity - 1).clamp(1, 99),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: AppText.numericStat,
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.add,
                    onTap: () => setState(
                      () => _quantity = (_quantity + 1).clamp(1, 99),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Guardar precios',
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
