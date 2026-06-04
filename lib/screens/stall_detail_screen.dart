import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/canteen_service.dart';
import 'cart_screen.dart';

class StallDetailScreen extends StatefulWidget {
  final String canteenId;
  final Stall stall;
  const StallDetailScreen(
      {super.key, required this.canteenId, required this.stall});

  @override
  State<StallDetailScreen> createState() => _StallDetailScreenState();
}

class _StallDetailScreenState extends State<StallDetailScreen> {
  List<MenuItem> _menu = [];
  bool _loading = true;
  // Cart: itemId → CartItem
  final Map<String, CartItem> _cart = {};
  String _activeCategory = '';

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final menu =
          await CanteenService().getMenu(widget.canteenId, widget.stall.id);
      setState(() {
        _menu = menu;
        _loading = false;
        if (menu.isNotEmpty) _activeCategory = menu.first.category;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  List<String> get _categories =>
      _menu.map((m) => m.category).toSet().toList();

  List<MenuItem> get _filteredMenu =>
      _menu.where((m) => m.category == _activeCategory).toList();

  int get _cartCount =>
      _cart.values.fold(0, (sum, c) => sum + c.quantity);

  double get _cartTotal =>
      _cart.values.fold(0.0, (sum, c) => sum + c.subtotal);

  void _addItem(MenuItem item) {
    if (!item.isAvailable) return;
    setState(() {
      if (_cart.containsKey(item.id)) {
        _cart[item.id]!.quantity++;
      } else {
        _cart[item.id] = CartItem(item: item);
      }
    });
  }

  void _removeItem(MenuItem item) {
    setState(() {
      if (_cart.containsKey(item.id)) {
        if (_cart[item.id]!.quantity > 1) {
          _cart[item.id]!.quantity--;
        } else {
          _cart.remove(item.id);
        }
      }
    });
  }

  void _goToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartScreen(
          canteenId: widget.canteenId,
          stall: widget.stall,
          cartItems: _cart.values.toList(),
        ),
      ),
    ).then((_) {
      // Clear cart after returning from a successful order
      // CartScreen pops with true on success
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stall Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stall header
                _buildStallHeader(),
                // Menu area
                Expanded(
                  child: _menu.isEmpty
                      ? const Center(child: Text('No menu items'))
                      : Row(
                          children: [
                            // Category sidebar
                            _buildCategorySidebar(),
                            // Items list
                            Expanded(child: _buildItemList()),
                          ],
                        ),
                ),
                // Cart bar
                if (_cartCount > 0) _buildCartBar(),
              ],
            ),
    );
  }

  Widget _buildStallHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront, color: Colors.orange, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.stall.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(widget.stall.rating.toStringAsFixed(1)),
                    const SizedBox(width: 12),
                    const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Queue: ${widget.stall.queueCount}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySidebar() {
    return Container(
      width: 80,
      color: Colors.grey.shade100,
      child: ListView(
        children: _categories
            .map((cat) => GestureDetector(
                  onTap: () => setState(() => _activeCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 14),
                    color: _activeCategory == cat
                        ? Colors.white
                        : Colors.transparent,
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: _activeCategory == cat
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _activeCategory == cat
                            ? Colors.orange
                            : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildItemList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredMenu.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final item = _filteredMenu[i];
        final qty = _cart[item.id]?.quantity ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Item icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lunch_dining, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600)),
                    Text('RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
              // Sold out badge or +/- controls
              if (!item.isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Sold Out',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                )
              else if (qty == 0)
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Colors.orange, size: 32),
                  onPressed: () => _addItem(item),
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          size: 28),
                      onPressed: () => _removeItem(item),
                    ),
                    Text('$qty',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          size: 28, color: Colors.orange),
                      onPressed: () => _addItem(item),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Text('$_cartCount',
                  style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            const Text('View Cart',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const Spacer(),
            Text('RM ${_cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _goToCart,
              child: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
