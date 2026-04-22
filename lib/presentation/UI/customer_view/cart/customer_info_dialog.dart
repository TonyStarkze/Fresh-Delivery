import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OrderType { delivery, takeAway }

class CustomerInfo {
  final String name;
  final String phone;
  final String address;
  final OrderType orderType;

  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.orderType,
  });
}

/// Dialog shown before WhatsApp checkout — collects customer name, phone,
/// address and delivery/takeaway preference. Persists data via SharedPreferences.
class CustomerInfoDialog extends StatefulWidget {
  const CustomerInfoDialog({super.key});

  @override
  State<CustomerInfoDialog> createState() => _CustomerInfoDialogState();
}

class _CustomerInfoDialogState extends State<CustomerInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  OrderType _orderType = OrderType.delivery;
  bool _saveForNext = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedInfo();
  }

  Future<void> _loadSavedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('customer_name') ?? '';
    _phoneController.text = prefs.getString('customer_phone') ?? '';
    _addressController.text = prefs.getString('customer_address') ?? '';
    final savedType = prefs.getString('customer_order_type');
    if (savedType == 'takeAway') {
      _orderType = OrderType.takeAway;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveInfo() async {
    if (_saveForNext) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customer_name', _nameController.text.trim());
      await prefs.setString('customer_phone', _phoneController.text.trim());
      await prefs.setString('customer_address', _addressController.text.trim());
      await prefs.setString(
        'customer_order_type',
        _orderType == OrderType.takeAway ? 'takeAway' : 'delivery',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Your Details',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Type Toggle
                      Text(
                        'Order Type',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<OrderType>(
                          segments: const [
                            ButtonSegment(
                              value: OrderType.delivery,
                              label: Text('🚚 Delivery'),
                            ),
                            ButtonSegment(
                              value: OrderType.takeAway,
                              label: Text('🏪 Take Away'),
                            ),
                          ],
                          selected: {_orderType},
                          onSelectionChanged: (selection) {
                            setState(() => _orderType = selection.first);
                          },
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Address (only required for delivery)
                      if (_orderType == OrderType.delivery)
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Delivery Address',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (_orderType == OrderType.delivery &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Address is required for delivery';
                            }
                            return null;
                          },
                        ),

                      const SizedBox(height: 12),

                      // Save for next time
                      CheckboxListTile(
                        title: Text(
                          'Save for next time',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        value: _saveForNext,
                        onChanged: (v) => setState(() => _saveForNext = v ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: _isLoading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _saveInfo();
                    if (context.mounted) {
                      Navigator.pop(
                        context,
                        CustomerInfo(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          address: _addressController.text.trim(),
                          orderType: _orderType,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Proceed'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
    );
  }
}
