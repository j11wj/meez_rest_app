import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';
import '../services/api_service.dart';

class RequestDriverScreen extends StatefulWidget {
  const RequestDriverScreen({super.key});

  @override
  State<RequestDriverScreen> createState() => _RequestDriverScreenState();
}

class _RequestDriverScreenState extends State<RequestDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _api = ApiService();

  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _pricings = [];
  String? _selectedZoneId;
  String _farePayedBy = 'CUSTOMER';
  bool _loading = true;
  bool _submitting = false;
  double? _detectedFare;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = context.read<AuthProvider>().token;
    try {
      final zones = await _api.getZones(token);
      final pricings = await _api.getZonePricings(token);
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _pricings = pricings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('فشل تحميل المناطق: $e');
    }
  }

  void _onZoneChanged(String? zoneId) {
    setState(() {
      _selectedZoneId = zoneId;
      _detectedFare = _getFare(zoneId);
    });
  }

  double? _getFare(String? toZoneId) {
    if (toZoneId == null) return null;
    final restaurantZoneId =
        context.read<RestaurantProvider>().restaurant?.zoneId;
    for (final p in _pricings) {
      final fromMatches = restaurantZoneId == null ||
          p['fromZoneId'] == restaurantZoneId;
      if (fromMatches && p['toZoneId'] == toZoneId) {
        return (p['price'] as num?)?.toDouble();
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedZoneId == null) {
      _showError('اختر منطقة الوجهة');
      return;
    }
    if (_detectedFare == null) {
      _showError('لا يوجد سعر توصيل محدد لهذه المنطقة');
      return;
    }

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().token;
      await _api.requestDriverOnly(
        token: token,
        toZoneId: _selectedZoneId!,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerAddress: _addressCtrl.text.trim(),
        farePayedBy: _farePayedBy,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب السائق بنجاح'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلب سائق توصيل'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Zone selector
                      _SectionTitle(title: 'منطقة الوجهة'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedZoneId,
                        decoration: _inputDecoration('اختر المنطقة'),
                        items: _zones
                            .map((z) => DropdownMenuItem(
                                  value: z['id'] as String,
                                  child: Text(z['name'] as String? ?? ''),
                                ))
                            .toList(),
                        onChanged: _onZoneChanged,
                        validator: (v) => v == null ? 'اختر منطقة' : null,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedZoneId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _detectedFare != null
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : AppTheme.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _detectedFare != null
                                  ? AppTheme.success
                                  : AppTheme.danger,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _detectedFare != null
                                    ? Icons.local_shipping_rounded
                                    : Icons.warning_amber_rounded,
                                size: 18,
                                color: _detectedFare != null
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _detectedFare != null
                                    ? 'أجرة التوصيل: ${_detectedFare!.toStringAsFixed(0)} IQD'
                                    : 'لا يوجد سعر محدد لهذه المنطقة',
                                style: TextStyle(
                                  color: _detectedFare != null
                                      ? AppTheme.success
                                      : AppTheme.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Customer info
                      _SectionTitle(title: 'معلومات العميل'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDecoration('اسم العميل'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'أدخل الاسم' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: _inputDecoration('رقم الهاتف'),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'أدخل رقم الهاتف' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: _inputDecoration('عنوان التوصيل'),
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'أدخل العنوان' : null,
                      ),

                      const SizedBox(height: 20),

                      // Who pays the fare
                      _SectionTitle(title: 'من يدفع أجرة التوصيل؟'),
                      const SizedBox(height: 8),
                      _FarePayerSelector(
                        value: _farePayedBy,
                        onChanged: (v) => setState(() => _farePayedBy = v),
                      ),

                      const SizedBox(height: 28),

                      ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.background),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_submitting ? 'جاري الإرسال...' : 'إرسال طلب السائق'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _FarePayerSelector extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _FarePayerSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceTile(
            label: 'العميل (كاش)',
            icon: Icons.person_rounded,
            selected: value == 'CUSTOMER',
            onTap: () => onChanged('CUSTOMER'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ChoiceTile(
            label: 'المطعم',
            icon: Icons.restaurant_rounded,
            selected: value == 'RESTAURANT',
            onTap: () => onChanged('RESTAURANT'),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceTile(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppTheme.background : AppTheme.textSecondary,
                size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppTheme.background : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
