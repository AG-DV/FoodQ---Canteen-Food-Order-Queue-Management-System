import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/canteen_service.dart';
// import '../services/auth_service.dart';
import 'stall_detail_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Bottom nav index
  int _navIndex = 0;

  // Canteen selection state
  Canteen? _selectedCanteen;
  List<Canteen> _canteens = [];

  // Stall list state
  List<Stall> _stalls = [];
  List<Stall> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _categoryFilter = 'All';

  static const _categories = ['All', 'Main Course', 'Snacks', 'Drinks'];

  @override
  void initState() {
    super.initState();
    _loadCanteens();
  }

  Future<void> _loadCanteens() async {
    try {
      final canteens = await CanteenService().getCanteens();
      setState(() {
        _canteens = canteens;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _selectCanteen(Canteen canteen) async {
    setState(() {
      _selectedCanteen = canteen;
      _loading = true;
      _stalls = [];
      _filtered = [];
    });
    try {
      final stalls = await CanteenService().getStalls(canteen.id);
      setState(() {
        _stalls = stalls;
        _filtered = stalls;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _stalls.where((s) {
        final matchSearch =
            s.name.toLowerCase().contains(_search.toLowerCase());
        final matchCat =
            _categoryFilter == 'All' || s.category == _categoryFilter;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screens = [_buildHomeTab(), const OrdersScreen(), const ProfileScreen()];
    return Scaffold(
      body: screens[_navIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    // If no canteen selected yet, show canteen picker
    if (_selectedCanteen == null) return _buildCanteenPicker();
    return _buildStallList();
  }

  // ─── Canteen Picker ──────────────────────────────────────────────────────

  Widget _buildCanteenPicker() {
    return Scaffold(
      appBar: AppBar(title: const Text('FoodQ'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _canteens.isEmpty
              ? const Center(child: Text('No canteens available'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _canteens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final c = _canteens[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.store)),
                        title: Text(c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(c.location),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectCanteen(c),
                      ),
                    );
                  },
                ),
    );
  }

  // ─── Stall List ──────────────────────────────────────────────────────────

  Widget _buildStallList() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCanteen!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _selectedCanteen = null;
            _stalls = [];
            _filtered = [];
          }),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search stalls or food',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) {
                _search = v;
                _applyFilter();
              },
            ),
          ),
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _categoryFilter == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) {
                    _categoryFilter = cat;
                    _applyFilter();
                  },
                );
              },
            ),
          ),
          // Stall cards
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('No stalls found'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _StallCard(
                          stall: _filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StallDetailScreen(
                                canteenId: _selectedCanteen!.id,
                                stall: _filtered[i],
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StallCard extends StatelessWidget {
  final Stall stall;
  final VoidCallback onTap;
  const _StallCard({required this.stall, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.storefront, color: Colors.orange),
        ),
        title: Text(stall.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            const Icon(Icons.people_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Queue: ${stall.queueCount} people',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(stall.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stall.isOpen ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                stall.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  fontSize: 11,
                  color: stall.isOpen ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: stall.isOpen ? onTap : null,
      ),
    );
  }
}
