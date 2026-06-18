import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/pos_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/customer.dart';
import '../../../models/pos_order.dart';
import '../../../models/product.dart';
import '../../layout/app_drawer.dart';
import 'pos_receipt_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PosScreen
// ─────────────────────────────────────────────────────────────────────────────
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _cashCtrl   = TextEditingController();
  Timer?  _debounce;
  bool    _cartOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (!mounted) return;
    final PosController ctrl = context.read<PosController>();
    final String? cid = context.read<AuthController>().activeCompanyId;
    ctrl.setCompanyId(cid);
    await Future.wait<void>(<Future<void>>[
      ctrl.loadProducts(),
      ctrl.loadCustomers(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _cashCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      context.read<PosController>().setProductSearch(q);
    });
  }

  Future<void> _openCustomerPicker() async {
    final PosController ctrl = context.read<PosController>();
    final Customer? picked = await showModalBottomSheet<Customer>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CustomerSheet(
        customers: ctrl.customers,
        selected: ctrl.selectedCustomer,
        isLoading: ctrl.isLoadingCustomers,
      ),
    );
    if (!mounted) return;
    if (picked != null) ctrl.selectCustomer(picked);
  }

  Future<void> _openPayment() async {
    final PosController ctrl = context.read<PosController>();
    if (ctrl.cartIsEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add items to the cart first')));
      return;
    }
    if (_cartOpen) setState(() => _cartOpen = false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _PaymentSheet(
          ctrl: ctrl,
          cashCtrl: _cashCtrl,
          onCheckout: _checkout,
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    final PosController ctrl = context.read<PosController>();
    if (ctrl.paymentMethod == PosPaymentMethod.cash) {
      final double given =
          double.tryParse(_cashCtrl.text.replaceAll(',', '')) ?? 0;
      ctrl.setCashGiven(given);
      if (given < ctrl.cartTotal) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cash given is less than total')));
        return;
      }
    }
    final PosOrder? order = await ctrl.checkout();
    if (!mounted) return;
    Navigator.of(context).pop();
    if (order != null) {
      _cashCtrl.clear();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (_) => PosReceiptScreen(order: order)),
      );
    } else if (ctrl.checkoutError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ctrl.checkoutError!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 700;
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          drawer: const AppDrawer(),
          appBar: _buildAppBar(wide),
          body: wide ? _wideBody() : _narrowBody(),
        );
      },
    );
  }

  AppBar _buildAppBar(bool wide) => AppBar(
        title: const Text('Point of Sale'),
        leading: Builder(
          builder: (BuildContext ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: <Widget>[
          if (!wide)
            Selector<PosController, int>(
              selector: (_, PosController c) => c.cartItemCount,
              builder: (_, int count, __) => Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => setState(() => _cartOpen = !_cartOpen),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Color(0xFFE53935), shape: BoxShape.circle),
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _SearchField(
                controller: _searchCtrl, onChanged: _onSearch),
          ),
        ),
      );

  Widget _wideBody() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Expanded(flex: 3, child: _ProductGrid()),
          Container(width: 1, color: const Color(0xFFE9EEF5)),
          SizedBox(
            width: 320,
            child: _CartPanel(
              onCustomer: _openCustomerPicker,
              onCheckout: _openPayment,
            ),
          ),
        ],
      );

  Widget _narrowBody() => Stack(
        children: <Widget>[
          const _ProductGrid(),
          if (_cartOpen)
            GestureDetector(
              onTap: () => setState(() => _cartOpen = false),
              child: Container(color: Colors.black.withValues(alpha: 0.36)),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            right: _cartOpen ? 0 : -320,
            top: 0,
            bottom: 0,
            width: 300,
            child: Material(
              elevation: 10,
              child: _CartPanel(
                onCustomer: _openCustomerPicker,
                onCheckout: _openPayment,
              ),
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchField
// ─────────────────────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search products…',
        hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9AA5B6), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE9EEF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProductGrid
// ─────────────────────────────────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context) {
    return Selector<PosController,
        ({List<Product> products, bool loading, String search})>(
      selector: (_, PosController c) => (
        products: c.filteredProducts,
        loading: c.isLoadingProducts,
        search: c.productSearch,
      ),
      builder: (BuildContext ctx,
          ({List<Product> products, bool loading, String search}) vm, _) {
        if (vm.loading) {
          return Skeletonizer(
            enabled: true,
            child: GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: 8,
              itemBuilder: (_, __) => const _ProductCardSkeleton(),
            ),
          );
        }
        if (vm.products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.inventory_2_outlined,
                      size: 52, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    vm.search.isEmpty
                        ? 'No products found'
                        : 'No results for "${vm.search}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF9AA5B6),
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ctx.read<PosController>().loadProducts(),
          child: GridView.builder(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: vm.products.length,
            itemBuilder: (BuildContext context, int i) {
              final Product p = vm.products[i];
              return _ProductTile(
                product: p,
                onTap: () => ctx.read<PosController>().addToCart(p),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProductTile
// ─────────────────────────────────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductTile({required this.product, required this.onTap});

  static String _price(double v) {
    if ((v - v.truncateToDouble()).abs() < 0.005) {
      return 'SAR ${v.toStringAsFixed(0)}';
    }
    return 'SAR ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final String init =
        product.name.trim().isNotEmpty ? product.name[0].toUpperCase() : 'P';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(init,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 28)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF0B1B4B),
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(_price(product.price),
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12)),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EEF5))),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CartPanel
// ─────────────────────────────────────────────────────────────────────────────
class _CartPanel extends StatelessWidget {
  final VoidCallback onCustomer;
  final VoidCallback onCheckout;
  const _CartPanel({required this.onCustomer, required this.onCheckout});

  static String _fmt(double v) {
    if ((v - v.truncateToDouble()).abs() < 0.005) return 'SAR ${v.toStringAsFixed(0)}';
    return 'SAR ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PosController,
        ({List<PosCartItem> cart, double sub, double tax, double total, Customer? customer, bool busy})>(
      selector: (_, PosController c) => (
        cart: c.cart,
        sub: c.cartSubtotal,
        tax: c.cartTax,
        total: c.cartTotal,
        customer: c.selectedCustomer,
        busy: c.isCheckingOut,
      ),
      builder: (BuildContext ctx,
          ({List<PosCartItem> cart, double sub, double tax, double total, Customer? customer, bool busy}) vm,
          _) {
        return ColoredBox(
          color: const Color(0xFFF7FAFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        bottom: BorderSide(color: Color(0xFFE9EEF5)))),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text('Cart',
                          style: TextStyle(
                              color: Color(0xFF0B1B4B),
                              fontWeight: FontWeight.w900,
                              fontSize: 16)),
                    ),
                    if (vm.cart.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            ctx.read<PosController>().clearCart(),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD93025),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),

              // Customer row
              GestureDetector(
                onTap: onCustomer,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9EEF5)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.person_outline,
                          color: Color(0xFF9AA5B6), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          vm.customer?.name ?? 'Walk-in Customer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: vm.customer != null
                                ? const Color(0xFF0B1B4B)
                                : const Color(0xFF9AA5B6),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF9AA5B6), size: 18),
                    ],
                  ),
                ),
              ),

              // Items list
              Expanded(
                child: vm.cart.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.shopping_cart_outlined,
                                size: 44, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            const Text('Cart is empty',
                                style: TextStyle(
                                    color: Color(0xFF9AA5B6),
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text('Tap a product to add it',
                                style: TextStyle(
                                    color: Color(0xFF9AA5B6),
                                    fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(12, 10, 12, 4),
                        itemCount: vm.cart.length,
                        itemBuilder: (BuildContext context, int i) {
                          final PosCartItem item = vm.cart[i];
                          return _CartItemTile(
                            item: item,
                            onIncrement: () =>
                                ctx.read<PosController>().incrementItem(i),
                            onDecrement: () =>
                                ctx.read<PosController>().decrementItem(i),
                            onRemove: () =>
                                ctx.read<PosController>().removeFromCart(i),
                          );
                        },
                      ),
              ),

              // Totals + charge button
              if (vm.cart.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          top: BorderSide(color: Color(0xFFE9EEF5)))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Subtotal',
                                style: TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            Text(_fmt(vm.sub),
                                style: const TextStyle(
                                    color: Color(0xFF0B1B4B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ]),
                      const SizedBox(height: 4),
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('VAT',
                                style: TextStyle(
                                    color: Color(0xFF6B7895),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            Text(_fmt(vm.tax),
                                style: const TextStyle(
                                    color: Color(0xFF0B1B4B),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12)),
                          ]),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child:
                            Divider(height: 1, color: Color(0xFFE9EEF5)),
                      ),
                      Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Total',
                                style: TextStyle(
                                    color: Color(0xFF0B1B4B),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15)),
                            Text(_fmt(vm.total),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18)),
                          ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed:
                              vm.busy ? null : onCheckout,
                          icon: vm.busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white))
                              : const Icon(
                                  Icons.point_of_sale_outlined),
                          label: Text(vm.busy
                              ? 'Processing…'
                              : 'Charge ${_fmt(vm.total)}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CartItemTile
// ─────────────────────────────────────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final PosCartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  static String _fmt(double v) {
    if ((v - v.truncateToDouble()).abs() < 0.005) return 'SAR ${v.toStringAsFixed(0)}';
    return 'SAR ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w800,
                        fontSize: 12)),
                const SizedBox(height: 2),
                Text(_fmt(item.price),
                    style: const TextStyle(
                        color: Color(0xFF9AA5B6),
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Qty controls
          Row(
            children: <Widget>[
              _QtyBtn(
                icon: Icons.remove,
                onTap: onDecrement,
                color: const Color(0xFFD93025),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('${item.qty}',
                    style: const TextStyle(
                        color: Color(0xFF0B1B4B),
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ),
              _QtyBtn(
                icon: Icons.add,
                onTap: onIncrement,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(_fmt(item.total),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12)),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.delete_outline,
                    size: 16, color: Color(0xFF9AA5B6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _QtyBtn(
      {required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 14, color: color),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// _CustomerSheet
// ─────────────────────────────────────────────────────────────────────────────
class _CustomerSheet extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selected;
  final bool isLoading;

  const _CustomerSheet({
    required this.customers,
    required this.selected,
    required this.isLoading,
  });

  @override
  State<_CustomerSheet> createState() => _CustomerSheetState();
}

class _CustomerSheetState extends State<_CustomerSheet> {
  String _q = '';

  List<Customer> get _filtered {
    if (_q.isEmpty) return widget.customers;
    final String lower = _q.toLowerCase();
    return widget.customers.where((Customer c) {
      return c.name.toLowerCase().contains(lower) ||
          c.email.toLowerCase().contains(lower) ||
          c.phone.contains(_q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Select Customer',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              onChanged: (String v) => setState(() => _q = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search customers…',
                hintStyle: const TextStyle(color: Color(0xFF9AA5B6)),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF9AA5B6), size: 18),
                filled: true,
                fillColor: const Color(0xFFF7FAFF),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFE9EEF5))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.2)),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.isLoading)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()))
            else if (widget.customers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No customers',
                      style: TextStyle(
                          color: Color(0xFF9AA5B6),
                          fontWeight: FontWeight.w700)),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    // Walk-in option
                    _CustomerTile(
                      name: 'Walk-in Customer',
                      subtitle: 'No invoice generated',
                      isSelected: widget.selected == null,
                      onTap: () => Navigator.of(context).pop<Customer?>(null),
                    ),
                    ..._filtered.map((Customer c) => _CustomerTile(
                          name: c.name,
                          subtitle: c.email.isNotEmpty
                              ? c.email
                              : c.phone,
                          isSelected: c.id == (widget.selected?.id ?? ''),
                          onTap: () =>
                              Navigator.of(context).pop<Customer>(c),
                        )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomerTile({
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7FAFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(name,
                        style: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xFF9AA5B6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF9AA5B6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PaymentSheet
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentSheet extends StatelessWidget {
  final PosController ctrl;
  final TextEditingController cashCtrl;
  final VoidCallback onCheckout;

  const _PaymentSheet({
    required this.ctrl,
    required this.cashCtrl,
    required this.onCheckout,
  });

  static String _fmt(double v) {
    if ((v - v.truncateToDouble()).abs() < 0.005) return 'SAR ${v.toStringAsFixed(0)}';
    return 'SAR ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFF0B1B4B),
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 16),

            // Order total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.splashBottom,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: <Widget>[
                  Text('Total',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Selector<PosController, double>(
                    selector: (_, PosController c) => c.cartTotal,
                    builder: (_, double total, __) => Text(
                      _fmt(total),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment method chips
            const Text('Payment Method',
                style: TextStyle(
                    color: Color(0xFF6B7895),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Selector<PosController, PosPaymentMethod>(
              selector: (_, PosController c) => c.paymentMethod,
              builder: (BuildContext ctx, PosPaymentMethod method, _) {
                return Row(
                  children: <Widget>[
                    _PayChip(
                      label: 'Cash',
                      icon: Icons.payments_outlined,
                      selected: method == PosPaymentMethod.cash,
                      onTap: () => ctrl
                          .setPaymentMethod(PosPaymentMethod.cash),
                    ),
                    const SizedBox(width: 8),
                    _PayChip(
                      label: 'Card',
                      icon: Icons.credit_card_outlined,
                      selected: method == PosPaymentMethod.card,
                      onTap: () => ctrl
                          .setPaymentMethod(PosPaymentMethod.card),
                    ),
                    const SizedBox(width: 8),
                    _PayChip(
                      label: 'Bank',
                      icon: Icons.account_balance_outlined,
                      selected:
                          method == PosPaymentMethod.bankTransfer,
                      onTap: () => ctrl.setPaymentMethod(
                          PosPaymentMethod.bankTransfer),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Cash given field (only for cash)
            Selector<PosController, PosPaymentMethod>(
              selector: (_, PosController c) => c.paymentMethod,
              builder: (_, PosPaymentMethod method, __) {
                if (method != PosPaymentMethod.cash) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text('Cash Given',
                        style: TextStyle(
                            color: Color(0xFF6B7895),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: cashCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.,]')),
                      ],
                      onChanged: (String v) {
                        final double given =
                            double.tryParse(v.replaceAll(',', '')) ??
                                0;
                        ctrl.setCashGiven(given);
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        hintStyle: const TextStyle(
                            color: Color(0xFF9AA5B6)),
                        prefixText: 'SAR  ',
                        prefixStyle: const TextStyle(
                            color: Color(0xFF0B1B4B),
                            fontWeight: FontWeight.w800),
                        filled: true,
                        fillColor: const Color(0xFFF7FAFF),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE9EEF5))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Selector<PosController, double>(
                      selector: (_, PosController c) => c.change,
                      builder: (_, double change, __) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFAF3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Change',
                                style: TextStyle(
                                    color: Color(0xFF1DB954),
                                    fontWeight: FontWeight.w800)),
                            Text(_fmt(change),
                                style: const TextStyle(
                                    color: Color(0xFF1DB954),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),

            // Confirm button
            Selector<PosController, bool>(
              selector: (_, PosController c) => c.isCheckingOut,
              builder: (_, bool busy, __) => SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: busy ? null : onCheckout,
                  icon: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                      busy ? 'Processing…' : 'Confirm Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PayChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : const Color(0xFFF7FAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : const Color(0xFFE9EEF5),
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF6B7895)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF6B7895),
                      fontWeight: FontWeight.w800,
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
