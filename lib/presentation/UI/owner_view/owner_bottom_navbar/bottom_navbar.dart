import 'package:delivery_webapp/presentation/UI/owner_view/category/category_view.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/menu/menu_view.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/offer/offer_view.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import 'package:delivery_webapp/presentation/widgets/custom_bottom_navbar.dart';

class BottomNavbar extends StatelessWidget {
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomBottomNavbar(
      pages: [
        CategoryView(),
        MenuView(),
        OfferView(),
        ProfileView(),
      ],
      tabs: [
        GButton(icon: Icons.category_rounded, text: 'CATEGORY'),
        GButton(icon: Icons.menu_book, text: 'MENU'),
        GButton(icon: Icons.local_offer, text: 'OFFERS'),
        GButton(icon: Icons.person, text: 'PROFILE'),
      ],
    );
  }
}
