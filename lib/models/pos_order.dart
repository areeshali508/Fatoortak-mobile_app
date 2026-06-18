enum PosPaymentMethod { cash, card, bankTransfer }

enum PosOrderStatus { paid, cancelled }

class PosCartItem {
  final String productId;
  final String name;
  final String sku;
  final double price;
  final double taxRate;
  final int qty;

  const PosCartItem({
    required this.productId,
    required this.name,
    required this.sku,
    required this.price,
    required this.taxRate,
    this.qty = 1,
  });

  double get subtotal => price * qty;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  PosCartItem copyWith({int? qty}) => PosCartItem(
        productId: productId,
        name: name,
        sku: sku,
        price: price,
        taxRate: taxRate,
        qty: qty ?? this.qty,
      );
}

class PosOrder {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final List<PosCartItem> items;
  final PosPaymentMethod paymentMethod;
  final PosOrderStatus status;
  final double cashGiven;
  final String? customerId;
  final String? customerName;
  final String? companyId;
  final String currency;

  const PosOrder({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.items,
    required this.paymentMethod,
    required this.status,
    required this.currency,
    this.cashGiven = 0,
    this.customerId,
    this.customerName,
    this.companyId,
  });

  double get subtotal =>
      items.fold(0.0, (double s, PosCartItem i) => s + i.subtotal);
  double get taxAmount =>
      items.fold(0.0, (double s, PosCartItem i) => s + i.taxAmount);
  double get total => subtotal + taxAmount;
  double get change => (cashGiven - total).clamp(0.0, double.infinity);
}
