import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/menu_item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';
import 'menu_item_form_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final res = context.read<RestaurantProvider>();
    await res.loadRestaurant(auth.token);
    if (mounted) await res.loadMenuItems(auth.token);
  }

  Future<void> _toggleOpen() async {
    final auth = context.read<AuthProvider>();
    await context.read<RestaurantProvider>().toggleOpen(auth.token);
  }

  Future<void> _toggleItem(String id) async {
    final auth = context.read<AuthProvider>();
    await context.read<RestaurantProvider>().toggleItemAvailability(id, auth.token);
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصنف'),
        content: const Text('هل أنت متأكد من حذف هذا الصنف؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await context.read<RestaurantProvider>().deleteItem(id, auth.token);
  }

  Future<void> _openForm([MenuItem? item]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MenuItemFormScreen(item: item)),
    );
    if (result == true && mounted) {
      final auth = context.read<AuthProvider>();
      await context.read<RestaurantProvider>().loadMenuItems(auth.token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = context.watch<RestaurantProvider>();
    final restaurant = res.restaurant;

    if (res.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (restaurant == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('تعذّر تحميل بيانات المطعم',
                style: TextStyle(color: Colors.black45)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(restaurant: restaurant, onToggle: _toggleOpen),
          const SizedBox(height: 16),
          _MenuHeader(onAdd: () => _openForm()),
          const SizedBox(height: 8),
          if (res.menuLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (res.menuItems.isEmpty)
            _EmptyMenu(onAdd: () => _openForm())
          else
            ...res.menuItems.map((item) => _MenuItemCard(
                  item: item,
                  onEdit: () => _openForm(item),
                  onToggle: () => _toggleItem(item.id),
                  onDelete: () => _deleteItem(item.id),
                )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final dynamic restaurant;
  final VoidCallback onToggle;
  const _StatusCard({required this.restaurant, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isOpen = restaurant.isOpen as bool;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isOpen ? AppTheme.success : AppTheme.danger).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOpen ? Icons.storefront : Icons.store_mall_directory_outlined,
                color: isOpen ? AppTheme.success : AppTheme.danger,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    isOpen ? 'المطعم مفتوح' : 'المطعم مغلق',
                    style: TextStyle(
                      fontSize: 13,
                      color: isOpen ? AppTheme.success : AppTheme.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isOpen,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppTheme.success,
              inactiveThumbColor: AppTheme.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const _MenuHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('قائمة الطعام',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppTheme.primary)),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة صنف'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _EmptyMenu extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyMenu({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.restaurant_menu, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            const Text('لا توجد أصناف بعد',
                style: TextStyle(color: Colors.black38, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('أضف أول صنف'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final addonsCount = item.suggestedAddons.length + item.suggestedSauces.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isAvailable ? AppTheme.success : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${item.price.toStringAsFixed(0)} IQD',
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      if (item.category != null && item.category!.isNotEmpty) ...[
                        const Text('  ·  ',
                            style: TextStyle(color: Colors.black26)),
                        Text(item.category!,
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 12)),
                      ],
                      if (addonsCount > 0) ...[
                        const Text('  ·  ',
                            style: TextStyle(color: Colors.black26)),
                        Text('$addonsCount إضافة',
                            style: const TextStyle(
                                color: AppTheme.primaryLight, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isAvailable
                      ? AppTheme.success.withAlpha(20)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.isAvailable
                        ? AppTheme.success.withAlpha(80)
                        : Colors.grey.withAlpha(80),
                  ),
                ),
                child: Text(
                  item.isAvailable ? 'متاح' : 'غير متاح',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.isAvailable ? AppTheme.success : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppTheme.primary,
              onPressed: onEdit,
              tooltip: 'تعديل',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppTheme.danger,
              onPressed: onDelete,
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
  }
}
