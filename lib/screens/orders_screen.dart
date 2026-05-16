import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/restaurant_provider.dart';
import 'order_detail_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRestaurant());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurant() async {
    final auth = context.read<AuthProvider>();
    await context.read<RestaurantProvider>().loadRestaurant(auth.token);
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    await context.read<OrdersProvider>().loadOrders(auth.token);
  }

  void _logout() async {
    context.read<OrdersProvider>().disposeSocket();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrdersProvider>();
    final auth = context.watch<AuthProvider>();
    final res = context.watch<RestaurantProvider>();
    final isOpen = res.restaurant?.isOpen;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('MEEZ POS'),
            Text(
              auth.user?.name ?? '',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (isOpen != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Tooltip(
                message: isOpen ? 'مفتوح' : 'مغلق',
                child: Icon(
                  Icons.storefront,
                  size: 20,
                  color: isOpen ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ),
          _SocketIndicator(connected: orders.socketConnected),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'تحديث',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'خروج',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'جديد (${orders.pendingOrders.length})'),
            Tab(text: 'جاري (${orders.activeOrders.length})'),
            const Tab(text: 'منتهي'),
            const Tab(icon: Icon(Icons.settings, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          orders.loading
              ? const Center(child: CircularProgressIndicator())
              : _OrderList(orders: orders.pendingOrders, onRefresh: _refresh),
          orders.loading
              ? const Center(child: CircularProgressIndicator())
              : _OrderList(orders: orders.activeOrders, onRefresh: _refresh),
          orders.loading
              ? const Center(child: CircularProgressIndicator())
              : _OrderList(orders: orders.doneOrders, onRefresh: _refresh),
          const SettingsScreen(),
        ],
      ),
    );
  }
}

class _SocketIndicator extends StatelessWidget {
  final bool connected;
  const _SocketIndicator({required this.connected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: connected ? 'متصل' : 'غير متصل',
        child: Icon(
          Icons.circle,
          size: 12,
          color: connected ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;

  const _OrderList({required this.orders, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 12),
            Text('لا توجد طلبات', style: TextStyle(color: Colors.black38, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: orders.length,
        itemBuilder: (ctx, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final statusLabel = _statusLabel(order.status);
    final time = DateFormat('HH:mm').format(order.createdAt.toLocal());
    final date = DateFormat('dd/MM').format(order.createdAt.toLocal());

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withAlpha(80)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${order.shortId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customer?.name ?? 'زبون',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$time  $date',
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
              if (order.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  order.items.map((i) => '${i.menuItemName} ×${i.quantity}').join(' • '),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: AppTheme.success),
                  Text(
                    ' ${order.total.toStringAsFixed(0)} IQD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.black26),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PENDING': return AppTheme.warning;
      case 'ACCEPTED': return AppTheme.primaryLight;
      case 'ON_THE_WAY': return Colors.teal;
      case 'DELIVERED': return AppTheme.success;
      case 'CANCELED': return AppTheme.danger;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'PENDING': return 'طلب جديد';
      case 'ACCEPTED': return 'مقبول';
      case 'ON_THE_WAY': return 'في الطريق';
      case 'DELIVERED': return 'تم التوصيل';
      case 'CANCELED': return 'ملغي';
      default: return s;
    }
  }
}
