import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import '../core/app_theme.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ScreenshotController _screenshotCtrl = ScreenshotController();
  bool _printing = false;

  Future<void> _updateStatus(String status) async {
    final auth = context.read<AuthProvider>();
    final ok = await context
        .read<OrdersProvider>()
        .updateStatus(widget.orderId, status, auth.token);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<OrdersProvider>().error ?? 'خطأ في تحديث الحالة'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  Future<void> _print(Order order) async {
    setState(() => _printing = true);
    try {
      // نبني الوصل أولاً — نمرر الطلب كاملاً بما فيه الأيتمات
      final imageBytes = await _screenshotCtrl.captureFromWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: _ReceiptWidget(order: order),
          ),
        ),
        pixelRatio: 3.0,
      );
      final image = await flutterImageProvider(MemoryImage(imageBytes));
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (ctx) => pw.Center(child: pw.Image(image)),
        ),
      );
      final pdfBytes = await doc.save();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersProvider>().findById(widget.orderId);
    if (order == null) {
      return const Scaffold(body: Center(child: Text('الطلب غير موجود')));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('طلب #${order.shortId}'),
        actions: [
          IconButton(
            icon: _printing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            onPressed: _printing ? null : () => _print(order),
            tooltip: 'طباعة الوصل',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusBanner(status: order.status),
            const SizedBox(height: 16),
            _InfoCard(order: order),
            const SizedBox(height: 12),
            _ItemsCard(order: order),
            const SizedBox(height: 12),
            _TotalsCard(order: order),
            const SizedBox(height: 20),
            _ActionButtons(
              order: order,
              onUpdateStatus: _updateStatus,
              onPrint: () => _print(order),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            _statusLabel(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  IconData _statusIcon(String s) {
    switch (s) {
      case 'PENDING': return Icons.notifications_active;
      case 'ACCEPTED': return Icons.check_circle_outline;
      case 'ON_THE_WAY': return Icons.delivery_dining;
      case 'DELIVERED': return Icons.done_all;
      case 'CANCELED': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Order order;
  const _InfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('dd/MM/yyyy  HH:mm').format(order.createdAt.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(Icons.tag, 'رقم الطلب', '#${order.shortId}'),
            _divider(),
            _row(Icons.person_outline, 'الزبون', order.customer?.name ?? '-'),
            if (order.customer?.phone != null) ...[
              _divider(),
              _row(Icons.phone_outlined, 'الهاتف', order.customer!.phone!),
            ],
            _divider(),
            _row(Icons.access_time, 'الوقت', time),
            _divider(),
            _row(Icons.payment, 'الدفع', order.paymentMethod == 'CASH' ? 'نقد' : order.paymentMethod),
            if (order.description != null && order.description!.isNotEmpty) ...[
              _divider(),
              _row(Icons.notes, 'ملاحظات', order.description!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppTheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(color: Colors.black45, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFEEEEEE));
}

// ─── Items Card ───────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final Order order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الأصناف',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primary)),
            const SizedBox(height: 12),
            if (order.items.isEmpty)
              const Text('لا توجد أصناف',
                  style: TextStyle(color: Colors.black38))
            else
              ...order.items.map((item) => _ItemRow(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantity}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuItemName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (item.notes != null && item.notes!.isNotEmpty)
                  Text(item.notes!,
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${item.itemTotal.toStringAsFixed(0)} IQD',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Totals Card ──────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  final Order order;
  const _TotalsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (order.subtotal > 0) _totalRow('المجموع الفرعي', order.subtotal),
            if (order.fare > 0) _totalRow('رسوم التوصيل', order.fare),
            if (order.discount > 0)
              _totalRow('الخصم', -order.discount, color: AppTheme.success),
            const Divider(height: 16),
            _totalRow('الإجمالي', order.total,
                bold: true, color: AppTheme.primary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount,
      {bool bold = false, Color? color, double size = 14}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color ?? Colors.black87,
      fontSize: size,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${amount.toStringAsFixed(0)} IQD', style: style),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final Order order;
  final void Function(String) onUpdateStatus;
  final VoidCallback onPrint;

  const _ActionButtons({
    required this.order,
    required this.onUpdateStatus,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _availableActions(order.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...actions.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: a.color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(a.icon),
                label: Text(a.label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: () => onUpdateStatus(a.nextStatus),
              ),
            )),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: AppTheme.primary),
          ),
          icon: const Icon(Icons.print, color: AppTheme.primary),
          label: const Text('طباعة الوصل',
              style: TextStyle(color: AppTheme.primary, fontSize: 15)),
          onPressed: onPrint,
        ),
      ],
    );
  }

  List<_Action> _availableActions(String status) {
    if (status == 'PENDING') {
      return [
        _Action('ACCEPTED', 'قبول الطلب', Icons.check_circle, AppTheme.success),
        _Action('CANCELED', 'إلغاء الطلب', Icons.cancel, AppTheme.danger),
      ];
    }
    return [];
  }
}

class _Action {
  final String nextStatus;
  final String label;
  final IconData icon;
  final Color color;
  _Action(this.nextStatus, this.label, this.icon, this.color);
}

// ─── Receipt Widget ───────────────────────────────────────────────────────────

class _ReceiptWidget extends StatelessWidget {
  final Order order;
  const _ReceiptWidget({required this.order});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt.toLocal());
    // نطبع كل الأيتمات — نأخذ نسخة من القائمة عند البناء
    final items = List<OrderItem>.from(order.items);

    return Container(
      width: 380,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              children: [
                Text('MEEZ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6),
                    textAlign: TextAlign.center),
                Text('ORDER RECEIPT',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11, letterSpacing: 3),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _row('Order', '#${order.shortId}', bold: true),
          _row('Date', time),
          _row('Customer', order.customer?.name ?? '-'),
          if (order.customer?.phone != null)
            _row('Phone', order.customer!.phone!),
          _row('Payment',
              order.paymentMethod == 'CASH' ? 'Cash' : order.paymentMethod),
          const SizedBox(height: 8),
          _dots(),
          const SizedBox(height: 8),
          // Items header
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('ITEMS',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Colors.black54)),
          ),
          const SizedBox(height: 6),
          // الأيتمات — نبنيها كـ Column بدل lazy map
          Column(
            children: items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text('${item.quantity}x ',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                          child: Text(item.menuItemName,
                              style: const TextStyle(fontSize: 13))),
                      Text('${item.itemTotal.toStringAsFixed(0)} IQD',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                )).toList(),
          ),
          const SizedBox(height: 8),
          _dots(),
          const SizedBox(height: 8),
          if (order.subtotal > 0)
            _row('Subtotal', '${order.subtotal.toStringAsFixed(0)} IQD'),
          if (order.fare > 0)
            _row('Delivery', '${order.fare.toStringAsFixed(0)} IQD'),
          if (order.discount > 0)
            _row('Discount', '- ${order.discount.toStringAsFixed(0)} IQD',
                valueColor: AppTheme.success),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primary)),
                Text('${order.total.toStringAsFixed(0)} IQD',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _dots(),
          const SizedBox(height: 12),
          const Text('Thank you!',
              style: TextStyle(
                  fontSize: 14, color: Colors.black38, letterSpacing: 1)),
          const SizedBox(height: 4),
          const Text('meez.app',
              style: TextStyle(
                  fontSize: 11, color: Colors.black26, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style:
                      const TextStyle(color: Colors.black45, fontSize: 12))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight:
                          bold ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                      color: valueColor ?? Colors.black87))),
        ],
      ),
    );
  }

  Widget _dots() {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DottedLinePainter()),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
