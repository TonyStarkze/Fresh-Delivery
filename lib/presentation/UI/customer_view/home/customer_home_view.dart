import 'dart:typed_data';
import 'package:delivery_webapp/data/models/menu_item_model.dart';
import 'package:delivery_webapp/logic/bloc/cart/cart_bloc.dart';
import 'package:delivery_webapp/logic/bloc/cart/cart_event.dart';
import 'package:delivery_webapp/logic/bloc/cart/cart_state.dart';
import 'package:delivery_webapp/logic/bloc/category/category_bloc.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_bloc.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_state.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_bloc.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_state.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:delivery_webapp/presentation/widgets/custom_bottom_navbar.dart';
import 'package:delivery_webapp/utils/cloudinary_services.dart';

class CustomerHomeView extends StatefulWidget {
  const CustomerHomeView({super.key});

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<CustomerHomeView> {
  final TextEditingController _searchTerm = TextEditingController();

  // Filter states
  final List<String> _selectedCategories = [];
  bool? _availabilityFilter;
  String _sortOption = 'default';

  @override
  void dispose() {
    _searchTerm.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredMenuItems(List<MenuItemModel> items) {
    final searchTerm = _searchTerm.text.toLowerCase().trim();

    var result = items.map((e) => e.toUIMap()).toList();

    result = result.where((item) {
      final name = (item['name'] as String).toLowerCase();
      final category = (item['category'] as String).toLowerCase();
      final desc = (item['description'] as String? ?? '').toLowerCase();

      final matchesSearch =
          searchTerm.isEmpty ||
          name.contains(searchTerm) ||
          category.contains(searchTerm) ||
          desc.contains(searchTerm);

      if (!matchesSearch) return false;

      if (_availabilityFilter != null &&
          item['available'] != _availabilityFilter) {
        return false;
      }

      if (_selectedCategories.isNotEmpty &&
          !_selectedCategories.contains(item['category'])) {
        return false;
      }

      return true;
    }).toList();

    switch (_sortOption) {
      case 'price_asc':
        result.sort((a, b) {
          final priceA =
              double.tryParse(
                (a['price'] as String).replaceAll('₹', '').trim(),
              ) ??
              0;
          final priceB =
              double.tryParse(
                (b['price'] as String).replaceAll('₹', '').trim(),
              ) ??
              0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_desc':
        result.sort((a, b) {
          final priceA =
              double.tryParse(
                (a['price'] as String).replaceAll('₹', '').trim(),
              ) ??
              0;
          final priceB =
              double.tryParse(
                (b['price'] as String).replaceAll('₹', '').trim(),
              ) ??
              0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'name_asc':
        result.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
        break;
      default:
        break;
    }

    return result;
  }

  Future<void> _showFilterDialog() async {
    bool? tempAvailability = _availabilityFilter;
    String tempSort = _sortOption;

    final result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter & Sort'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Availability',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: tempAvailability == null,
                        onSelected: (_) {
                          setDialogState(() => tempAvailability = null);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Available'),
                        selected: tempAvailability == true,
                        onSelected: (_) {
                          setDialogState(() => tempAvailability = true);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Out of Stock'),
                        selected: tempAvailability == false,
                        onSelected: (_) {
                          setDialogState(() => tempAvailability = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sort By',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Default'),
                        selected: tempSort == 'default',
                        onSelected: (_) {
                          setDialogState(() => tempSort = 'default');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Price ↑'),
                        selected: tempSort == 'price_asc',
                        onSelected: (_) {
                          setDialogState(() => tempSort = 'price_asc');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Price ↓'),
                        selected: tempSort == 'price_desc',
                        onSelected: (_) {
                          setDialogState(() => tempSort = 'price_desc');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Name A-Z'),
                        selected: tempSort == 'name_asc',
                        onSelected: (_) {
                          setDialogState(() => tempSort = 'name_asc');
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'reset'),
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'availability': tempAvailability,
                      'sort': tempSort,
                    });
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
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
    final allCategoriesNames = categoriesState.categories
        .map((e) => e.name)
        .toList();

    final shopName = shopProfileState.profile.name;
    final isShopOpen = shopProfileState.profile.isOpen;
    final timings = shopProfileState.profile.timings;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 70,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            Text(
              shopName,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isShopOpen ? Icons.storefront : Icons.storefront_outlined,
                  color: isShopOpen ? Colors.greenAccent : Colors.redAccent,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isShopOpen ? 'Open • $timings' : 'Closed',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isShopOpen ? Colors.white70 : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isShopOpen)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'The shop is currently closed. You cannot place orders right now.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      Text(
                        'Our Menu',
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search + Filter row
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
                                borderRadius: BorderRadius.all(
                                  Radius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _showFilterDialog,
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.white,
                          ),
                          iconSize: 25,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.black,
                            ),
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

                  // Category chips
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
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey[400]!,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Offer Banners Carousel Slider
                  BlocBuilder<OfferBloc, OfferState>(
                    builder: (context, offerState) {
                      if (offerState.offers.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 150.0,
                            autoPlay: true,
                            enlargeCenterPage: true,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.85,
                            autoPlayInterval: const Duration(seconds: 4),
                          ),
                          items: offerState.offers.map((offer) {
                            return Builder(
                              builder: (BuildContext context) {
                                return Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.network(
                                      cldUrl(offer.imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  // Delivery time banner
                  if (shopProfileState.profile.deliveryTimeLabel != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade50,
                            Colors.blue.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 18,
                            color: Colors.indigo.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            shopProfileState.profile.deliveryTimeLabel!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Menu grid
                  BlocBuilder<MenuBloc, MenuState>(
                    builder: (context, menuState) {
                        if (menuState.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final filteredMenuItems = _getFilteredMenuItems(
                          menuState.items,
                        );

                        if (filteredMenuItems.isEmpty) {
                          return Center(
                            child: Text(
                              'No items found',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return BlocBuilder<CartBloc, CartState>(
                          builder: (context, cartState) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                left: 10,
                                right: 10,
                                top: 10,
                                bottom: 100,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 250,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    // ── Increased from 0.85 → 0.72 so the card
                                    //    is taller relative to its width, giving
                                    //    the button breathing room on small phones.
                                    childAspectRatio: 0.72,
                                  ),
                              itemCount: filteredMenuItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredMenuItems[index];
                                final qty = cartState.getQty(item['name']);
                                return _CustomerMenuCard(
                                  item: item,
                                  qty: qty,
                                  isShopOpen: isShopOpen,
                                  onAdd: () {
                                    if (!isShopOpen) return;
                                    context.read<CartBloc>().add(
                                      AddToCart(item: item),
                                    );
                                    if (qty == 0) {
                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '"${item['name']}" added to cart',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            action: SnackBarAction(
                                              label: 'GO TO CART',
                                              textColor: Colors.white,
                                              onPressed: () {
                                                final navState = context
                                                    .findAncestorStateOfType<
                                                      CustomBottomNavbarState
                                                    >();
                                                navState?.switchTab(1);
                                              },
                                            ),
                                          ),
                                        );
                                    }
                                  },
                                  onRemove: () {
                                    if (!isShopOpen) return;
                                    context.read<CartBloc>().add(
                                      RemoveFromCart(item: item),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared image placeholder helper
// ─────────────────────────────────────────────
Widget _imagePlaceholder() => Container(
      color: Colors.grey[300],
      child: const Icon(Icons.store, size: 36, color: Colors.grey),
    );

// ─────────────────────────────────────────────
// Customer-facing menu card
// ─────────────────────────────────────────────
class _CustomerMenuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int qty;
  final bool isShopOpen;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _CustomerMenuCard({
    required this.item,
    required this.qty,
    required this.isShopOpen,
    required this.onAdd,
    required this.onRemove,
  });

  bool get _hasOffer {
    final offer = item['offerPrice'] as String?;
    return offer != null && offer.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // If shop is closed, treat everything as unavailable.
    final bool isAvailable =
        isShopOpen && (item['available'] as bool? ?? false);

    return ColorFiltered(
      colorFilter: isAvailable
          ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
          : const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // clipBehavior rounds the image corners without needing a nested ClipRRect
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // ── mainAxisSize.min means the Column only takes what it needs;
          //    the grid cell constrains the outer size, so the button
          //    is never pushed outside the card boundary.
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Fixed-height image ──────────────────────────────────────
            // AspectRatio(16/9) was the culprit: on a 180px-wide cell it
            // consumed ~101px, leaving too little room for content + button.
            // A fixed 90px is predictable on every screen size.
            SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item['webImage'] != null
                      ? Image.memory(
                          item['webImage'] as Uint8List,
                          fit: BoxFit.cover,
                        )
                      : (item['image'] != null &&
                            (item['image'] as String).isNotEmpty)
                      ? Image.network(
                          cldUrl(item['image']),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                        )
                      : _imagePlaceholder(),
                  // OFFER badge
                  if (_hasOffer)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OFFER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            // Natural column flow — no Expanded fighting aspect ratio.
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    item['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Description (skip the SizedBox gap if empty)
                  if ((item['description'] as String? ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['description'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 4),

                  // Price — with offer support
                  if (_hasOffer)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['unit'] != null &&
                                  (item['unit'] as String).isNotEmpty
                              ? '${item['price']} / ${item['unit']}'
                              : item['price'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item['unit'] != null &&
                                  (item['unit'] as String).isNotEmpty
                              ? '${item['offerPrice']} / ${item['unit']}'
                              : item['offerPrice'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  else
                    Text(
                      item['unit'] != null &&
                              (item['unit'] as String).isNotEmpty
                          ? '${item['price']} / ${item['unit']}'
                          : item['price'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 7),

                  // ── Button — always the last child, always inside the card ──
                  if (isAvailable)
                    qty == 0
                        // ADD button
                        ? SizedBox(
                            width: double.infinity,
                            height: 34,
                            child: ElevatedButton(
                              onPressed: onAdd,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        // Qty stepper
                        : SizedBox(
                            height: 34,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  // ── Expanded tap targets fill the full
                                  //    third each, making - and + easy to hit
                                  //    on small screens (no more 40px SizedBox).
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: onRemove,
                                      child: const SizedBox(
                                        height: 34,
                                        child: Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$qty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: onAdd,
                                      child: const SizedBox(
                                        height: 34,
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                  else
                    // Disabled state
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          !isShopOpen ? 'CLOSED' : 'UNAVAILABLE',
                          style: const TextStyle(fontSize: 11),
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
  }
}