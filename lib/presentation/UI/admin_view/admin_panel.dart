import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import 'package:delivery_webapp/utils/constants.dart';

/*
// COPY AND PASTE THESE RULES INTO FIREBASE CONSOLE -> FIRESTORE DATABASE -> RULES
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Multi-tenant architecture rules
    // Match the specific shop document based on the owner's UID
    match /shops/{shopId} {
      
      // Allow customers (anyone) to read the shop's data
      allow read: if true;
      
      // Allow owners to write ONLY to their specific shopId
      allow write: if request.auth != null && request.auth.uid == shopId;
      
      // Allow admin to create shops
      // REPLACE 'your_admin_email@example.com' with your actual admin email
      allow create: if request.auth != null && request.auth.token.email == 'your_admin_email@example.com';
      
      // Apply the same rules cascade to all subcollections
      // (e.g. shops/{shopId}/categories/{categoryId})
      match /{document=**} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == shopId;
      }
    }
  }
}
*/

class AdminPanel extends StatefulWidget {
  // --- ADMIN CONSTANTS ---
  static const String adminEmail =
      'ADMIN EMAIL FOR SEETTING RESTAURANTS OF CLIENTS'; // CHANGE THIS TO YOUR EMAIL
  static const String firebaseConsoleUsersUrl =
      'https://console.firebase.google.com/project/YOUR_PROJECT_ID/authentication/users';

  // --- EMAILJS CONSTANTS ---
  static const String emailJsServiceId = 'service_u21lmus'; // CHANGE THIS
  static const String emailJsTemplateId = 'template_tdjsm8h'; // CHANGE THIS
  static const String emailJsPublicKey = emailJsPublicKey_const;
  static const String appUrl = 'https://YOUR_PROJECT_ID.web.app/#/login';

  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _ownerEmailController = TextEditingController();
  final _tempPasswordController = TextEditingController();

  final _ownerNameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _ownerUidController = TextEditingController();
  final _ownerWhatsAppController = TextEditingController();

  bool _isUserCreatedInFirebase = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _ownerEmailController.dispose();
    _tempPasswordController.dispose();
    _ownerNameController.dispose();
    _restaurantNameController.dispose();
    _ownerUidController.dispose();
    _ownerWhatsAppController.dispose();
    super.dispose();
  }

  Future<void> _openFirebaseConsole() async {
    final url = Uri.parse(AdminPanel.firebaseConsoleUsersUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Firebase Console')),
        );
      }
    }
  }

  Future<void> _createShopInFirestore() async {
    final uid = _ownerUidController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final restaurantName = _restaurantNameController.text.trim();
    final ownerEmail = _ownerEmailController.text.trim();
    final ownerWhatsApp = _ownerWhatsAppController.text.trim();

    await FirebaseFirestore.instance.collection('shops').doc(uid).set({
      'ownerName': ownerName,
      'name': restaurantName,
      'email': ownerEmail,
      'whatsappNumber': ownerWhatsApp,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _buildWelcomeMessage() {
    final ownerName = _ownerNameController.text.trim();
    final restaurantName = _restaurantNameController.text.trim();
    final ownerEmail = _ownerEmailController.text.trim();
    final tempPassword = _tempPasswordController.text.trim();

    final buffer = StringBuffer();
    buffer.writeln('🎉 *Welcome to Fresh Delivery!*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('Hi *$ownerName*,');
    buffer.writeln('');
    buffer.writeln('Your restaurant *$restaurantName* has been onboarded!');
    buffer.writeln('');
    buffer.writeln('🔐 *Login Credentials:*');
    buffer.writeln('📧 Email: $ownerEmail');
    buffer.writeln('🔑 Password: $tempPassword');
    buffer.writeln('');
    buffer.writeln('🌐 *Login here:*');
    buffer.writeln(AdminPanel.appUrl);
    buffer.writeln('');
    buffer.writeln('Thank you! 🙏');
    return buffer.toString();
  }

  Future<void> _createShopAndSendEmail() async {
    if (!_step2FormKey.currentState!.validate() ||
        !_step1FormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ownerName = _ownerNameController.text.trim();
      final restaurantName = _restaurantNameController.text.trim();
      final ownerEmail = _ownerEmailController.text.trim();
      final tempPassword = _tempPasswordController.text.trim();

      // 1. Create Firestore Document
      await _createShopInFirestore();

      // 2. Send Email via EmailJS
      final emailResponse = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': AdminPanel.emailJsServiceId,
          'template_id': AdminPanel.emailJsTemplateId,
          'user_id': AdminPanel.emailJsPublicKey,
          'template_params': {
            'owner_name': ownerName,
            'restaurant_name': restaurantName,
            'email': ownerEmail,
            'password': tempPassword,
            'app_url': AdminPanel.appUrl,
          },
        }),
      );

      if (emailResponse.statusCode != 200) {
        throw Exception('Failed to send email: ${emailResponse.body}');
      }

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner created and email sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createShopAndSendWhatsApp() async {
    if (!_step2FormKey.currentState!.validate() ||
        !_step1FormKey.currentState!.validate()) {
      return;
    }

    final ownerWhatsApp = _ownerWhatsAppController.text.trim();
    if (ownerWhatsApp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Owner WhatsApp number is required to send via WhatsApp',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create Firestore Document
      await _createShopInFirestore();

      // 2. Open WhatsApp with welcome message
      final message = Uri.encodeComponent(_buildWelcomeMessage());
      final whatsappUrl = 'https://wa.me/$ownerWhatsApp?text=$message';
      web.window.open(whatsappUrl, '_blank');

      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner created — WhatsApp message opened'),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _ownerEmailController.clear();
    _tempPasswordController.clear();
    _ownerNameController.clear();
    _restaurantNameController.clear();
    _ownerUidController.clear();
    _ownerWhatsAppController.clear();
    setState(() {
      _isUserCreatedInFirebase = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Onboard Owner'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStep1(),
                if (_isUserCreatedInFirebase) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),
                  _buildStep2(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 1: Create Auth User',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ownerEmailController,
                decoration: const InputDecoration(
                  labelText: 'Owner Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Temporary Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openFirebaseConsole,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Firebase Console'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text(
                  'I have created the user in Firebase Console',
                ),
                value: _isUserCreatedInFirebase,
                onChanged: (value) {
                  setState(() {
                    _isUserCreatedInFirebase = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 2: Create Shop & Notify Owner',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(
                  labelText: 'Owner Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _restaurantNameController,
                decoration: const InputDecoration(
                  labelText: 'Restaurant Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerUidController,
                decoration: const InputDecoration(
                  labelText: 'Owner UID (Paste from Firebase)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerWhatsAppController,
                decoration: const InputDecoration(
                  labelText: 'Owner WhatsApp Number (optional for email)',
                  hintText: 'e.g. +919876543210',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),

              // Two buttons: Send via Email  |  Send via WhatsApp
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _createShopAndSendEmail,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.email),
                      label: const Text('Send via Email'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _createShopAndSendWhatsApp,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.chat),
                      label: const Text('Send via WhatsApp'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
