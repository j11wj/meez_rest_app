import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/menu_item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/restaurant_provider.dart';

class MenuItemFormScreen extends StatefulWidget {
  final MenuItem? item;
  const MenuItemFormScreen({super.key, this.item});

  @override
  State<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends State<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _categoryCtrl;
  late bool _isAvailable;
  late List<MenuOptionRow> _addons;
  late List<MenuOptionRow> _sauces;
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _descCtrl = TextEditingController(text: i?.description ?? '');
    _priceCtrl = TextEditingController(
        text: i != null ? i.price.toStringAsFixed(0) : '');
    _categoryCtrl = TextEditingController(text: i?.category ?? '');
    _isAvailable = i?.isAvailable ?? true;
    _addons = List.from(i?.suggestedAddons ?? []);
    _sauces = List.from(i?.suggestedSauces ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final res = context.read<RestaurantProvider>();

    final data = {
      'restaurantId': res.restaurant!.id,
      'name': _nameCtrl.text.trim(),
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      if (_categoryCtrl.text.trim().isNotEmpty) 'category': _categoryCtrl.text.trim(),
      'isAvailable': _isAvailable,
      'suggestedAddons': _addons.map((a) => a.toJson()).toList(),
      'suggestedSauces': _sauces.map((s) => s.toJson()).toList(),
    };

    final bool ok;
    if (_isEdit) {
      ok = await res.updateItem(widget.item!.id, data, auth.token);
    } else {
      ok = await res.createItem(data, auth.token);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.error ?? 'فشل الحفظ'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل الصنف' : 'صنف جديد'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('حفظ',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('المعلومات الأساسية', [
              _field(_nameCtrl, 'اسم الصنف', required: true),
              const SizedBox(height: 12),
              _field(_descCtrl, 'الوصف (اختياري)'),
              const SizedBox(height: 12),
              _field(_priceCtrl, 'السعر (IQD)', required: true, number: true),
              const SizedBox(height: 12),
              _field(_categoryCtrl, 'التصنيف (اختياري)'),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
                title: const Text('متاح للطلب',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                activeThumbColor: AppTheme.success,
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            const SizedBox(height: 8),
            _buildOptionsSection(
              title: 'الإضافات',
              icon: Icons.add_circle_outline,
              rows: _addons,
              onAdd: () => _addOption(_addons),
              onRemove: (i) => setState(() => _addons.removeAt(i)),
              onEdit: (i) => _editOption(_addons, i),
            ),
            const SizedBox(height: 8),
            _buildOptionsSection(
              title: 'الصلصات',
              icon: Icons.soup_kitchen_outlined,
              rows: _sauces,
              onAdd: () => _addOption(_sauces),
              onRemove: (i) => setState(() => _sauces.removeAt(i)),
              onEdit: (i) => _editOption(_sauces, i),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    fontSize: 14)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, bool number = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null
          : null,
    );
  }

  Widget _buildOptionsSection({
    required String title,
    required IconData icon,
    required List<MenuOptionRow> rows,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required void Function(int) onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ],
            ),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('لا يوجد',
                    style: TextStyle(color: Colors.black38, fontSize: 13)),
              )
            else
              ...rows.asMap().entries.map((e) {
                final idx = e.key;
                final row = e.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${row.price.toStringAsFixed(0)} IQD',
                          style: const TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppTheme.primary,
                        onPressed: () => onEdit(idx),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppTheme.danger,
                        onPressed: () => onRemove(idx),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addOption(List<MenuOptionRow> list) {
    _showOptionDialog(null, (row) => setState(() => list.add(row)));
  }

  void _editOption(List<MenuOptionRow> list, int idx) {
    _showOptionDialog(list[idx], (row) => setState(() => list[idx] = row));
  }

  void _showOptionDialog(
      MenuOptionRow? existing, void Function(MenuOptionRow) onSave) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة خيار' : 'تعديل الخيار'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'الاسم'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر (IQD)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              onSave(MenuOptionRow(
                name: nameCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text.trim()) ?? 0,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
