import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../shared/models/menu_item_model.dart';
import '../repository/menu_repository.dart';

class MenuManagementScreen extends StatefulWidget {
  final String stallId;
  const MenuManagementScreen({super.key, required this.stallId});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _repo = MenuRepository();
  StreamSubscription<List<MenuItemModel>>? _sub;
  List<MenuItemModel> _items = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  static const _categories = ['All', 'Main Course', 'Snacks', 'Drinks', 'Set Meals'];

  @override
  void initState() {
    super.initState();
    _sub = _repo.watchMenuItems(widget.stallId).listen((items) {
      if (mounted) setState(() { _items = items; _loading = false; });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<MenuItemModel> get _filtered => _selectedCategory == 'All'
      ? _items
      : _items.where((i) => i.category == _selectedCategory).toList();

  Future<void> _toggleAvailability(MenuItemModel item) async {
    setState(() {
      final idx = _items.indexWhere((i) => i.itemId == item.itemId);
      if (idx != -1) _items[idx] = item.copyWith(isAvailable: !item.isAvailable);
    });
    try {
      await _repo.toggleAvailability(widget.stallId, item.itemId, !item.isAvailable);
    } catch (_) {
      setState(() {
        final idx = _items.indexWhere((i) => i.itemId == item.itemId);
        if (idx != -1) _items[idx] = item;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update availability')),
        );
      }
    }
  }

  Future<void> _deleteItem(MenuItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: Text('Remove "${item.name}" from your menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _items.removeWhere((i) => i.itemId == item.itemId));
      try {
        await _repo.deleteMenuItem(widget.stallId, item.itemId);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Failed to delete item')));
        }
      }
    }
  }

  void _openSheet({MenuItemModel? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddEditItemSheet(
        stallId: widget.stallId,
        repo: _repo,
        existingItem: item,
        categories: _categories.where((c) => c != 'All').toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _openSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      return FilterChip(
                        label: Text(cat),
                        selected: cat == _selectedCategory,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text('No items in this category',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _MenuItemCard(
                            item: _filtered[i],
                            onToggle: () => _toggleAvailability(_filtered[i]),
                            onEdit: () => _openSheet(item: _filtered[i]),
                            onDelete: () => _deleteItem(_filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemModel item;
  final VoidCallback onToggle, onEdit, onDelete;
  const _MenuItemCard({
    required this.item,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: item.isAvailable ? null : Colors.grey,
                            decoration: item.isAvailable ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      if (!item.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: const Text('Sold Out',
                              style: TextStyle(
                                  color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.description,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('RM ${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.category,
                            style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Switch(value: item.isAvailable, onChanged: (_) => onToggle(), activeTrackColor: Colors.green),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEditItemSheet extends StatefulWidget {
  final String stallId;
  final MenuRepository repo;
  final MenuItemModel? existingItem;
  final List<String> categories;
  const _AddEditItemSheet({
    required this.stallId,
    required this.repo,
    required this.categories,
    this.existingItem,
  });

  @override
  State<_AddEditItemSheet> createState() => _AddEditItemSheetState();
}

class _AddEditItemSheetState extends State<_AddEditItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _descCtrl, _priceCtrl, _limitCtrl;
  late String _category;
  bool _saving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _priceCtrl = TextEditingController(text: item != null ? item.price.toStringAsFixed(2) : '');
    _limitCtrl = TextEditingController(text: item?.dailyPreOrderLimit.toString() ?? '50');
    _category = item?.category ?? widget.categories.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final newItem = MenuItemModel(
      itemId: widget.existingItem?.itemId ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim()),
      category: _category,
      isAvailable: widget.existingItem?.isAvailable ?? true,
      dailyPreOrderLimit: int.tryParse(_limitCtrl.text.trim()) ?? 50,
    );

    try {
      if (_isEditing) {
        await widget.repo.updateMenuItem(widget.stallId, widget.existingItem!.itemId, newItem.toMap());
      } else {
        await widget.repo.addMenuItem(widget.stallId, newItem);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save item')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_isEditing ? 'Edit Item' : 'Add New Item',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Item Name *'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price (RM) *'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Price required';
                        if (double.tryParse(v.trim()) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _limitCtrl,
                      decoration: const InputDecoration(labelText: 'Daily Limit'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEditing ? 'Save Changes' : 'Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
