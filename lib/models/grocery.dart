class Supermarket {
  const Supermarket({this.id, required this.name});
  final int? id;
  final String name;

  Map<String, Object?> toMap() => {'id': id, 'name': name};
  static Supermarket fromMap(Map<String, Object?> m) =>
      Supermarket(id: m['id'] as int?, name: m['name'] as String);
}

class Product {
  const Product({
    this.id,
    required this.name,
    this.note,
    this.prices = const {},
  });

  final int? id;
  final String name;
  final String? note;

  /// Precio por unidad por id de supermercado. Ausente = sin homólogo.
  final Map<int, double> prices;

  double? priceAt(int supermarketId) => prices[supermarketId];

  Product copyWith({String? name, String? note, Map<int, double>? prices}) =>
      Product(
        id: id,
        name: name ?? this.name,
        note: note ?? this.note,
        prices: prices ?? this.prices,
      );

  Map<String, Object?> toMap() => {'id': id, 'name': name, 'note': note};
  static Product fromMap(Map<String, Object?> m) => Product(
    id: m['id'] as int?,
    name: m['name'] as String,
    note: m['note'] as String?,
  );
}

class CartItem {
  const CartItem({
    this.id,
    required this.product,
    this.quantity = 1,
    this.checked = false,
  });

  final int? id;
  final Product product;
  final int quantity;
  final bool checked;

  double? totalAt(int supermarketId) {
    final p = product.priceAt(supermarketId);
    return p == null ? null : p * quantity;
  }

  CartItem copyWith({Product? product, int? quantity, bool? checked}) =>
      CartItem(
        id: id,
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        checked: checked ?? this.checked,
      );
}

/// Resultado de valorar la cesta completa en un supermercado.
class BasketQuote {
  const BasketQuote({
    required this.supermarket,
    required this.total,
    required this.coveredItems,
    required this.totalItems,
  });

  final Supermarket supermarket;
  final double total;
  final int coveredItems;
  final int totalItems;

  bool get isComplete => coveredItems == totalItems;
}
