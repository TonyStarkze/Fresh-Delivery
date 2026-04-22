import 'package:delivery_webapp/data/models/category_model.dart';
import 'package:delivery_webapp/logic/bloc/category/category_bloc.dart';
import 'package:delivery_webapp/logic/bloc/category/category_event.dart';
import 'package:delivery_webapp/logic/bloc/category/category_state.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_bloc.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_bloc.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/category/dialogs/add_or_update.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/category/dialogs/delete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({super.key});

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final TextEditingController _searchTerm = TextEditingController();

  @override
  void dispose() {
    _searchTerm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopProfileState = context.watch<ShopProfileBloc>().state;
    final menuItemsMap = context.watch<MenuBloc>().state.items;

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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                Text(
                  'Categories',
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
                    onPressed: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return const Center(
                            child: Wrap(children: [AddOrUpdate(label: 'add')]),
                          );
                        },
                      );

                      if (result != null && mounted) {
                        context.read<CategoryBloc>().add(
                          AddCategory(CategoryModel(id: '', name: result)),
                        );
                      }
                    },
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final query = _searchTerm.text.toLowerCase().trim();
                  final filteredCategories = state.categories.where((category) {
                    return category.name.toLowerCase().contains(query);
                  }).toList();

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Text(
                        'No categories found',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      // Calculate item count dynamically based on MenuBloc items
                      final itemCount = menuItemsMap
                          .where((item) => item.category == category.name)
                          .length;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                255,
                                240,
                                103,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.restaurant_menu_outlined,
                              color: Colors.black,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Chip(
                                label: Text(
                                  '$itemCount ITEMS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                backgroundColor: Colors.blueGrey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 40,
                                width: 40,
                                child: IconButton(
                                  onPressed: () async {
                                    final result = await showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Center(
                                          child: Wrap(
                                            children: [
                                              AddOrUpdate(
                                                label: 'edit',
                                                category: category,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );

                                    if (result != null && mounted) {
                                      context.read<CategoryBloc>().add(
                                        EditCategory(
                                          CategoryModel(
                                            id: category.id,
                                            name: result,
                                          ),
                                          oldName: category.name,
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                width: 40,
                                child: IconButton(
                                  onPressed: () async {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return DeleteCategory(
                                          category: category,
                                          itemCount: itemCount,
                                        );
                                      },
                                    );

                                    if (result == true && mounted) {
                                      context.read<CategoryBloc>().add(
                                        RemoveCategory(category.id),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
