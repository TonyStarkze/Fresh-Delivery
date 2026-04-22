import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_bloc.dart';
import 'package:delivery_webapp/logic/bloc/cart/cart_bloc.dart';
import 'package:delivery_webapp/logic/bloc/cart/cart_event.dart';
import 'package:delivery_webapp/logic/bloc/cart/cart_state.dart';
import 'package:delivery_webapp/presentation/UI/customer_view/cart/customer_info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:web/web.dart' as web;

import 'package:delivery_webapp/utils/cloudinary_services.dart';

class CartView extends StatelessWidget {
  const CartView({super.key});

  /// Returns the effective price string for an item (offerPrice if set, else price).
  String _effectivePrice(Map<String, dynamic> item) {
    final offer = item['offerPrice'] as String?;
    return (offer != null && offer.isNotEmpty) ? offer : item['price'] as String;
  }

  bool _hasOffer(Map<String, dynamic> item) {
    final offer = item['offerPrice'] as String?;
    return offer != null && offer.isNotEmpty;
  }

  void _checkout(
    BuildContext context,
    CartState cartState,
    String whatsappNumber, {
    String? deliveryTimeLabel,
  }) async {
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show customer info dialog
    final customerInfo = await showDialog<CustomerInfo>(
      context: context,
      builder: (context) => const CustomerInfoDialog(),
    );

    if (customerInfo == null) return; // User cancelled
    if (!context.mounted) return;

    final isTakeAway = customerInfo.orderType == OrderType.takeAway;

    // Build WhatsApp message
    final buffer = StringBuffer();
    buffer.writeln('📋 *ORDER SUMMARY*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    int serialNo = 1;
    for (final entry in cartState.items.entries) {
      final item = entry.value;
      final name = item['name'] as String;
      final effectivePriceStr = _effectivePrice(item).replaceAll('₹', '').trim();
      final effectivePrice = double.tryParse(effectivePriceStr) ?? 0;
      final qty = item['qty'] as int;
      final unit = item['unit'] as String? ?? '';
      final subtotal = effectivePrice * qty;

      buffer.writeln('*$serialNo. $name*');
      if (unit.isNotEmpty) {
        buffer.writeln('     📦 $unit');
      }

      // Show offer info if applicable
      if (_hasOffer(item)) {
        final originalStr = (item['price'] as String).replaceAll('₹', '').trim();
        buffer.writeln(
          '     💰 ~₹$originalStr~ → ₹$effectivePriceStr × $qty = *₹${subtotal.toStringAsFixed(2)}*',
        );
      } else {
        buffer.writeln(
          '     💰 ₹$effectivePriceStr × $qty = *₹${subtotal.toStringAsFixed(2)}*',
        );
      }
      buffer.writeln('');
      serialNo++;
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('🧾 *Items:* ${cartState.totalItems}');
    buffer.writeln('💵 *Total: ₹${cartState.totalPrice.toStringAsFixed(2)}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    // Customer details
    buffer.writeln('👤 *Name:* ${customerInfo.name}');
    buffer.writeln('📱 *Phone:* ${customerInfo.phone}');
    if (isTakeAway) {
      buffer.writeln('🏪 *Order Type:* Take Away');
    } else {
      buffer.writeln('🚚 *Order Type:* Delivery');
      if (customerInfo.address.isNotEmpty) {
        buffer.writeln('📍 *Address:* ${customerInfo.address}');
      }
    }
    buffer.writeln('');
    buffer.writeln('Please confirm my order 🙏');

    final message = Uri.encodeComponent(buffer.toString());
    final whatsappUrl = 'https://wa.me/$whatsappNumber?text=$message';

    // If delivery time is set AND it's not a take-away, show popup
    if (deliveryTimeLabel != null && !isTakeAway) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          // Auto-close after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 48,
                  color: Colors.indigo.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  deliveryTimeLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Redirecting to WhatsApp...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.indigo.shade400,
                  ),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        // Open WhatsApp after popup closes
        web.window.open(whatsappUrl, '_blank');

        if (context.mounted) {
          context.read<CartBloc>().add(const ClearCart());
        }
      });
    } else {
      // Instant delivery or take-away — open immediately
      web.window.open(whatsappUrl, '_blank');

      if (context.mounted) {
        context.read<CartBloc>().add(const ClearCart());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirecting to WhatsApp...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProfileState = context.watch<ShopProfileBloc>().state;
    final shopName = shopProfileState.profile.name;
    final whatsappNumber = shopProfileState.profile.whatsappNumber;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '$shopName - Cart',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items from the menu to get started',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          final items = cartState.items.values.toList();

          return Column(
            children: [
              // Cart items list
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 100, // Extra padding to scroll past checkout bar and SnackBar
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final name = item['name'] as String;
                        final effectivePriceStr = _effectivePrice(item)
                            .replaceAll('₹', '')
                            .trim();
                        final effectivePrice = double.tryParse(effectivePriceStr) ?? 0;
                        final qty = item['qty'] as int;
                        final unit = item['unit'] as String? ?? '';
                        final subtotal = effectivePrice * qty;
                        final hasOffer = _hasOffer(item);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Item image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    cldUrl(item['image'] ?? '', width: 200),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.store,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Item details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      // Price with offer support
                                      if (hasOffer)
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 2,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              unit.isNotEmpty
                                                  ? '${item['price']} / $unit'
                                                  : item['price'],
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: Colors.grey,
                                                decoration: TextDecoration.lineThrough,
                                                decorationColor: Colors.grey,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              unit.isNotEmpty
                                                  ? '${item['offerPrice']} / $unit'
                                                  : item['offerPrice'],
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          unit.isNotEmpty
                                              ? '${item['price']} / $unit'
                                              : item['price'],
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${subtotal.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Qty counter
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          context.read<CartBloc>().add(
                                            RemoveFromCart(item: item),
                                          );
                                        },
                                        child: const SizedBox(
                                          width: 34,
                                          height: 34,
                                          child: Icon(
                                            Icons.remove,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 28,
                                        child: Center(
                                          child: Text(
                                            '$qty',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          context.read<CartBloc>().add(
                                            AddToCart(item: item),
                                          );
                                        },
                                        child: const SizedBox(
                                          width: 34,
                                          height: 34,
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bottom checkout bar
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${cartState.totalItems} item${cartState.totalItems > 1 ? 's' : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${cartState.totalPrice.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _checkout(
                                context,
                                cartState,
                                whatsappNumber,
                                deliveryTimeLabel:
                                    shopProfileState.profile.deliveryTimeLabel,
                              ),
                              icon: const Icon(Icons.send, size: 18),
                              label: const Text(
                                'Checkout via WhatsApp',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
