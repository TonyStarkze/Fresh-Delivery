import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:delivery_webapp/logic/bloc/auth/auth_bloc.dart';
import 'package:delivery_webapp/logic/bloc/auth/auth_event.dart';
import 'package:delivery_webapp/logic/bloc/auth/auth_state.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_bloc.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_event.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_state.dart';
import 'package:delivery_webapp/data/models/shop_profile_model.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _timingsController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  bool _isShopOpen = true;
  bool _isInstantDelivery = true;
  String _deliveryTimeUnit = 'minutes'; // 'minutes' or 'hours'

  @override
  void initState() {
    super.initState();
    final profile = context.read<ShopProfileBloc>().state.profile;
    _updateFields(profile);
  }

  void _updateFields(ShopProfileModel profile) {
    _shopNameController.text = profile.name;
    _whatsappController.text = profile.whatsappNumber;
    _timingsController.text = profile.timings;
    _isShopOpen = profile.isOpen;

    final mins = profile.deliveryTimeMinutes;
    _isInstantDelivery = mins <= 0;
    if (mins > 0) {
      if (mins >= 1440 && mins % 1440 == 0) {
        _deliveryTimeUnit = 'days';
        _deliveryTimeController.text = '${mins ~/ 1440}';
      } else if (mins >= 60 && mins % 60 == 0) {
        _deliveryTimeUnit = 'hours';
        _deliveryTimeController.text = '${mins ~/ 60}';
      } else {
        _deliveryTimeUnit = 'minutes';
        _deliveryTimeController.text = '$mins';
      }
    } else {
      _deliveryTimeController.text = '';
    }
  }

  int _computeDeliveryTimeMinutes() {
    if (_isInstantDelivery) return 0;
    final value = int.tryParse(_deliveryTimeController.text.trim()) ?? 0;
    if (value <= 0) return 0;
    switch (_deliveryTimeUnit) {
      case 'days':
        return value * 1440;
      case 'hours':
        return value * 60;
      default:
        return value;
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _whatsappController.dispose();
    _timingsController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout ?? false) {
      if (mounted) {
        context.read<AuthBloc>().add(const AuthLogoutRequested());
      }
    }
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedProfile = ShopProfileModel(
        name: _shopNameController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        timings: _timingsController.text.trim(),
        isOpen: _isShopOpen,
        deliveryTimeMinutes: _computeDeliveryTimeMinutes(),
      );
      context.read<ShopProfileBloc>().add(SaveShopProfile(updatedProfile));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved successfully'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.unauthenticated) {
              context.go('/login');
            }
          },
        ),
        BlocListener<ShopProfileBloc, ShopProfileState>(
          listenWhen: (previous, current) => previous.profile != current.profile,
          listener: (context, state) {
            setState(() {
              _updateFields(state.profile);
            });
          },
        ),
      ],
      child: BlocBuilder<ShopProfileBloc, ShopProfileState>(
        builder: (context, profileState) {
          final isLoading = profileState.isLoading;
          return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.indigo,
                          child: Icon(
                            Icons.store,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Shop Owner',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Manage your shop settings',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Shop Name Field
                  _buildTextField(
                    controller: _shopNameController,
                    label: 'Shop Name',
                    hint: 'Enter your shop name',
                    icon: Icons.store,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Shop name cannot be empty';
                      }
                      if (value.length < 3) {
                        return 'Minimum 3 characters required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // WhatsApp Field
                  _buildTextField(
                    controller: _whatsappController,
                    label: 'WhatsApp Number',
                    hint: 'Enter WhatsApp number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'WhatsApp number is required';
                      }
                      if (!value.startsWith('+')) {
                        return 'Start with country code (e.g., +123)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Shop Status Toggle
                  _buildStatusToggle(),

                  const SizedBox(height: 20),

                  // Shop Timings Field
                  _buildTextField(
                    controller: _timingsController,
                    label: 'Shop Timings',
                    hint: 'e.g., 09:00 AM - 09:00 PM',
                    icon: Icons.access_time,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Shop timings are required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Delivery Time Section
                  _buildDeliveryTimeSection(),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildShareMenuSection(),

                  const SizedBox(height: 24),

                  // Divider
                  const Divider(),

                  const SizedBox(height: 8),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),

          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.indigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(
            _isShopOpen ? Icons.storefront : Icons.storefront_outlined,
            color: Colors.indigo,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shop Status',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  _isShopOpen ? 'Open for business' : 'Currently closed',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _isShopOpen,
            onChanged: (value) {
                    setState(() {
                      _isShopOpen = value;
                    });
                  },
            activeThumbColor: Colors.indigo,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, color: Colors.indigo),
              const SizedBox(width: 12),
              const Text(
                'Delivery Time',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Instant Delivery option
          RadioListTile<bool>(
            title: const Text('Instant Delivery'),
            subtitle: Text(
              'Orders will be delivered immediately',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: true,
            groupValue: _isInstantDelivery,
            onChanged: (value) {
              setState(() {
                _isInstantDelivery = true;
                _deliveryTimeController.clear();
              });
            },
            activeColor: Colors.indigo,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),

          // Preorder Time option
          RadioListTile<bool>(
            title: const Text('Set Preorder Time'),
            subtitle: Text(
              'Specify expected delivery time',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            value: false,
            groupValue: _isInstantDelivery,
            onChanged: (value) {
              setState(() {
                _isInstantDelivery = false;
              });
            },
            activeColor: Colors.indigo,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),

          // Time input (visible only when preorder is selected)
          if (!_isInstantDelivery) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 8),
                const Text(
                  'Within',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _deliveryTimeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: 'e.g. 1',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (!_isInstantDelivery) {
                        final v = int.tryParse(value?.trim() ?? '');
                        if (v == null || v <= 0) {
                          return 'Required';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _deliveryTimeUnit,
                      items: const [
                        DropdownMenuItem(
                          value: 'minutes',
                          child: Text('Minutes'),
                        ),
                        DropdownMenuItem(
                          value: 'hours',
                          child: Text('Hours'),
                        ),
                        DropdownMenuItem(
                          value: 'days',
                          child: Text('Days'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _deliveryTimeUnit = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareMenuSection() {
    final String? uid = context.read<AuthBloc>().state.uid;
    final String customerUrl = '${Uri.base.origin}/#/shop/${uid ?? 'unknown'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Share Your Menu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customers can scan this QR code or visit the link to view your menu without logging in.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: QrImageView(
              data: customerUrl,
              version: QrVersions.auto,
              size: 150.0,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    customerUrl,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.indigo,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: customerUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard!')),
                    );
                  },
                  child: const Icon(Icons.copy, size: 20, color: Colors.indigo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

