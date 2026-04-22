import 'dart:typed_data';
import 'package:delivery_webapp/utils/cloudinary_services.dart';
import 'package:delivery_webapp/data/models/offer_item_model.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_bloc.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_event.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_state.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/offer/dialogs/add_or_update_offer.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/offer/dialogs/delete_offer.dart';
import 'package:uuid/uuid.dart';

class OfferView extends StatefulWidget {
  const OfferView({super.key});

  @override
  State<OfferView> createState() => _OfferViewState();
}

class _OfferViewState extends State<OfferView> {
  @override
  void initState() {
    super.initState();
    // Assuming context.read<OfferBloc>().add(LoadOffers()) is called elsewhere
    // when shopId is available (e.g. at login), if not, ensure it's called.
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddOrUpdateOfferDialog(),
    );

    if (result != null && mounted) {
      final mapItem = result as Map<String, dynamic>;
      final newItem = OfferItemModel(
        id: const Uuid().v4(),
        title: mapItem['title'],
        imageUrl: mapItem['image'] ?? '',
      );

      context.read<OfferBloc>().add(
        AddOffer(newItem, imageFile: mapItem['imageFile']),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddOrUpdateOfferDialog(item: item),
    );

    if (result != null && mounted) {
      final mapItem = result as Map<String, dynamic>;
      final updatedItem = OfferItemModel(
        id: item['id'],
        title: mapItem['title'],
        imageUrl: mapItem['image'] ?? '',
      );

      context.read<OfferBloc>().add(
        EditOffer(updatedItem, imageFile: mapItem['imageFile']),
      );
    }
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteOfferDialog(item: item),
    );

    if (result == true && mounted) {
      context.read<OfferBloc>().add(RemoveOffer(item['id']));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProfileState = context.watch<ShopProfileBloc>().state;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          shopProfileState.profile.name,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<OfferBloc, OfferState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed: ${state.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Promotional Banners',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      label: const Text(
                        'Add',
                        style: TextStyle(
                          fontWeight: .bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: _showAddDialog,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: BlocBuilder<OfferBloc, OfferState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.offers.isEmpty) {
                      return Center(
                        child: Text(
                          'No active banners',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    // For banners, a ListView is often better than a GridView due to extreme aspect ratios (e.g. 16:9).
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      itemCount: state.offers.length,
                      itemBuilder: (context, index) {
                        final item = state.offers[index].toUIMap();
                        return OfferCard(
                          item: item,
                          onEdit: () => _showEditDialog(item),
                          onDelete: () => _showDeleteDialog(item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Offer Card Widget
class OfferCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const OfferCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['title'] as String?;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: title != null && title.isNotEmpty
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      )
                    : BorderRadius.circular(15),
                child: AspectRatio(
                  aspectRatio: 16 / 9, // Enforced landscape ratio for preview
                  child: item['webImage'] != null
                      ? Image.memory(
                          item['webImage'] as Uint8List,
                          fit: BoxFit.cover,
                        )
                      : (item['image'] != null &&
                            (item['image'] as String).isNotEmpty)
                      ? Image.network(
                          cldUrl(item['image']),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              if (title != null && title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Action Buttons Overlay
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  style: IconButton.styleFrom(backgroundColor: Colors.white70),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  style: IconButton.styleFrom(backgroundColor: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
