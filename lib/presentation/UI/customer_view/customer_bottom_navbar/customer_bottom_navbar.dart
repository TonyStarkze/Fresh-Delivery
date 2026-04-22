import 'package:delivery_webapp/presentation/UI/customer_view/home/customer_home_view.dart';
import 'package:delivery_webapp/presentation/UI/customer_view/cart/cart_view.dart';
import 'package:delivery_webapp/presentation/widgets/custom_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CustomerBottomNavbar extends StatelessWidget {
  const CustomerBottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomBottomNavbar(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      pages: [
        CustomerHomeView(),
        CartView(),
      ],
      tabs: [
        GButton(icon: Icons.home, text: 'HOME'),
        GButton(icon: Icons.shopping_cart, text: 'CART'),
      ],
    );
  }
}
