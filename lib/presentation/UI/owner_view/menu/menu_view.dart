import 'dart:typed_data';
import 'package:delivery_webapp/utils/cloudinary_services.dart';
import 'package:delivery_webapp/data/models/menu_item_model.dart';
import 'package:delivery_webapp/logic/bloc/category/category_bloc.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_bloc.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_event.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_state.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/menu/dialogs/add_or_update.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/menu/dialogs/delete.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/menu/dialogs/filter.dart';
import 'package:uuid/uuid.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  final TextEditingController _searchTerm = TextEditingController();

  // Filter states
  final List<String> _selectedCategories = [];
  bool? _availabilityFilter; // null = all, true = available, false = out of stock

  // Sort state
  String _sortOption = 'default';

  @override
  void dispose() {
    _searchTerm.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredMenuItems(List<MenuItemModel> items) {
    final searchTerm = _searchTerm.text.toLowerCase().trim();

    // Convert to generic map to match existing UI
    var result = items.map((e) => e.toUIMap()).toList();

    // 1. Apply filters (search + category chips + availability)
    result = result.where((item) {
      final name = (item['name'] as String).toLowerCase();
      final category = (item['category'] as String).toLowerCase();
      final desc = (item['description'] as String? ?? '').toLowerCase();

      final matchesSearch = searchTerm.isEmpty ||
          name.contains(searchTerm) ||
          category.contains(searchTerm) ||
          desc.contains(searchTerm);

      if (!matchesSearch) return false;

      // Availability filter
      if (_availabilityFilter != null &&
          item['available'] != _availabilityFilter) {
        return false;
      }

      // Category filter from chips
      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(item['category'])) {
        return false;
      }

      return true;
    }).toList();

    // 2. Apply sorting
    switch (_sortOption) {
      case 'price_asc':
        result.sort((a, b) {
          final priceA = double.tryParse((a['price'] as String).replaceAll('₹', '').trim()) ?? 0;
          final priceB = double.tryParse((b['price'] as String).replaceAll('₹', '').trim()) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;

      case 'price_desc':
        result.sort((a, b) {
          final priceA = double.tryParse((a['price'] as String).replaceAll('₹', '').trim()) ?? 0;
          final priceB = double.tryParse((b['price'] as String).replaceAll('₹', '').trim()) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;

      case 'name_asc':
        result.sort((a, b) {
          return (a['name'] as String).compareTo(b['name'] as String);
        });
        break;

      default:
        break;
    }

    return result;
  }

  Future<void> _showAddDialog(List<String> allCategories) async {
    if (allCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a category first!')),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (context) => AddOrUpdateMenuItem(allCategories: allCategories),
    );

    if (result != null && mounted) {
      final mapItem = result as Map<String, dynamic>;
      final newItem = MenuItemModel(
        id: const Uuid().v4(), // temporary id, firestore will give real one
        name: mapItem['name'],
        price: mapItem['price'],
        offerPrice: mapItem['offerPrice'],
        description: mapItem['description'],
        category: mapItem['category'],
        unit: mapItem['unit'],
        available: mapItem['available'],
        imageUrl: mapItem['image'] ?? '',
      );
      
      context.read<MenuBloc>().add(AddMenuItem(newItem, imageFile: mapItem['imageFile']));
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> item, List<String> allCategories) async {
    if (allCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a category first before editing!')),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (context) => AddOrUpdateMenuItem(item: item, allCategories: allCategories),
    );

    if (result != null && mounted) {
      final mapItem = result as Map<String, dynamic>;
      final updatedItem = MenuItemModel(
        id: item['id'],
        name: mapItem['name'],
        price: mapItem['price'],
        offerPrice: mapItem['offerPrice'],
        description: mapItem['description'],
        category: mapItem['category'],
        unit: mapItem['unit'],
        available: mapItem['available'],
        imageUrl: mapItem['image'] ?? '',
      );
      
      context.read<MenuBloc>().add(EditMenuItem(updatedItem, imageFile: mapItem['imageFile']));
    }
  }

  Future<void> _showDeleteDialog(Map<String, dynamic> item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteMenuItem(item: item),
    );

    if (result == true && mounted) {
      context.read<MenuBloc>().add(RemoveMenuItem(item['id']));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item['name']}" deleted'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => FilterMenuDialog(
        initialAvailabilityFilter: _availabilityFilter,
        initialSortOption: _sortOption,
      ),
    );

    if (result == 'reset') {
      setState(() {
        _selectedCategories.clear();
        _availabilityFilter = null;
        _sortOption = 'default';
      });
    } else if (result is Map) {
      setState(() {
        _availabilityFilter = result['availability'] as bool?;
        _sortOption = result['sort'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProfileState = context.watch<ShopProfileBloc>().state;
    final categoriesState = context.watch<CategoryBloc>().state;
    final allCategoriesNames = categoriesState.categories.map((e) => e.name).toList();

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
      body: BlocListener<MenuBloc, MenuState>(
        listenWhen: (previous, current) => previous.error != current.error && current.error != null,
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
              Row(
                children: [
                  const SizedBox(width: 10),
                  Text(
                    'Menu Items',
                    style: GoogleFonts.inter(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchTerm,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showAddDialog(allCategoriesNames),
                      icon: const Icon(Icons.add, color: Colors.white),
                      iconSize: 25,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.black),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      iconSize: 25,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.black),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: allCategoriesNames.map((cat) {
                    final isSelected = _selectedCategories.contains(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        elevation: 0,
                        pressElevation: 0,
                        side: BorderSide(
                          color: isSelected ? Colors.black : Colors.grey[400]!,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: BlocBuilder<MenuBloc, MenuState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredMenuItems = _getFilteredMenuItems(state.items);

                    if (filteredMenuItems.isEmpty) {
                      return Center(
                        child: Text(
                          'No items found',
                          style: GoogleFonts.inter(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 10,
                        bottom: 80, // Extra padding to scroll past SnackBar
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 250,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: filteredMenuItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredMenuItems[index];
                        return MenuCard(
                          item: item,
                          onEdit: () => _showEditDialog(item, allCategoriesNames),
                          onDelete: () => _showDeleteDialog(item),
                          onToggleAvailability: () {
                            final updatedModel = MenuItemModel(
                              id: item['id'],
                              name: item['name'],
                              price: item['price'],
                              offerPrice: item['offerPrice'],
                              description: item['description'],
                              category: item['category'],
                              unit: item['unit'],
                              available: !item['available'],
                              imageUrl: item['image'],
                            );
                            context.read<MenuBloc>().add(EditMenuItem(updatedModel));
                          },
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

// Reusable Menu Card Widget
class MenuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const MenuCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = item['available'] as bool;
    return ColorFiltered(
      colorFilter: isAvailable
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 1, 0,
            ]),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: item['webImage'] != null
                        ? Image.memory(
                            item['webImage'] as Uint8List,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : (item['image'] != null && (item['image'] as String).isNotEmpty) 
                            ? Image.network(
                                cldUrl(item['image']),
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.store,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.store,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(15),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'toggle':
                          onToggleAvailability();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              isAvailable
                                  ? Icons.remove_circle_outline
                                  : Icons.check_circle_outline,
                              size: 20,
                              color: isAvailable ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isAvailable
                                  ? 'Mark Out of Stock'
                                  : 'Mark Available',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.more_vert, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? Colors.green.withValues(alpha: 0.9)
                          : Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Sold Out',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['description'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildPriceDisplay(item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDisplay(Map<String, dynamic> item) {
    final unit = item['unit'] as String? ?? '';
    final unitSuffix = unit.isNotEmpty ? ' / $unit' : '';
    final offerPrice = item['offerPrice'] as String?;
    final hasOffer = offerPrice != null && offerPrice.isNotEmpty;

    TextStyle priceStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.green.shade700,
    );

    TextStyle oldPriceStyle = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.grey,
      decoration: TextDecoration.lineThrough,
      decorationColor: Colors.grey,
    );

    if (hasOffer) {
      return Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            item['price'] + unitSuffix,
            style: oldPriceStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            offerPrice + unitSuffix,
            style: priceStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      item['price'] + unitSuffix,
      style: priceStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
