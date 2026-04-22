import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class CustomBottomNavbar extends StatefulWidget {
  final List<Widget> pages;
  final List<GButton> tabs;
  final MainAxisAlignment mainAxisAlignment;

  const CustomBottomNavbar({
    super.key,
    required this.pages,
    required this.tabs,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  });

  @override
  State<CustomBottomNavbar> createState() => CustomBottomNavbarState();
}

class CustomBottomNavbarState extends State<CustomBottomNavbar> {
  int selectedIndex = 0;

  void switchTab(int index) {
    if (index >= 0 && index < widget.pages.length) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: widget.pages[selectedIndex],
        bottomNavigationBar: Container(
          color: Colors.black,
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
                child: GNav(
                  selectedIndex: selectedIndex,
              mainAxisAlignment: widget.mainAxisAlignment,
              gap: 5,
              backgroundColor: Colors.black,
              activeColor: Colors.white,
              color: Colors.white,
              tabBackgroundColor: Colors.grey.shade800,
              padding: const EdgeInsets.all(16),
              onTabChange: (index) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                setState(() {
                  selectedIndex = index;
                });
              },
              tabs: widget.tabs,
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
