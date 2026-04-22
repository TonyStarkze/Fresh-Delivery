import 'dart:async';
import 'package:delivery_webapp/data/repositories/category_repository.dart';
import 'package:delivery_webapp/data/repositories/menu_repository.dart';
import 'package:delivery_webapp/data/repositories/shop_profile_repository.dart';
import 'package:delivery_webapp/logic/bloc/auth/auth_bloc.dart';
import 'package:delivery_webapp/logic/bloc/auth/auth_state.dart';
import 'package:delivery_webapp/logic/bloc/category/category_bloc.dart';
import 'package:delivery_webapp/logic/bloc/category/category_event.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_bloc.dart';
import 'package:delivery_webapp/logic/bloc/menu/menu_event.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_bloc.dart';
import 'package:delivery_webapp/logic/bloc/shop_profile/shop_profile_event.dart';
import 'package:delivery_webapp/data/repositories/offer_repository.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_bloc.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_event.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/owner_bottom_navbar/bottom_navbar.dart';
import 'package:delivery_webapp/presentation/UI/customer_view/customer_bottom_navbar/customer_bottom_navbar.dart';
import 'package:delivery_webapp/presentation/UI/admin_view/admin_panel.dart';
import 'package:delivery_webapp/presentation/UI/not_found/not_found_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_webapp/presentation/UI/owner_view/login/login_view.dart';

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: AuthListenable(authBloc),
      redirect: (context, state) {
        final authState = authBloc.state;
        final authenticated = authState.status == AuthStatus.authenticated;
        
        final path = state.uri.path;

        if (authenticated) {
          // If logged in, owners should land on their dashboard
          if (path == '/login' || path == '/') {
            return '/owner-bottom-nav';
          }
          // Allow them to visit /shop/:id if they want to see the customer view
          // Allow them to visit /admin to see the admin panel if they type it manually
        } else {
          // If not logged in, they can only be on /shop/:id, /login, or /admin
          if (!path.startsWith('/shop/') && path != '/login' && path != '/admin') {
            return '/login';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: '/owner-bottom-nav',
          name: 'owner-bottom-nav',
          builder: (context, state) {
            final uid = authBloc.state.uid;
            if (uid == null) {
              return const Scaffold(body: Center(child: Text("Error: Not authenticated")));
            }

            // Set the shop ID for the owner's session
            context.read<CategoryRepository>().setShopId(uid);
            context.read<MenuRepository>().setShopId(uid);
            context.read<ShopProfileRepository>().setShopId(uid);
            context.read<OfferRepository>().setShopId(uid);
            context.read<OfferBloc>().add(LoadOffers());

            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => CategoryBloc(repository: context.read<CategoryRepository>())..add(LoadCategories()),
                ),
                BlocProvider(
                  create: (context) => MenuBloc(repository: context.read<MenuRepository>())..add(LoadMenuItems()),
                ),
                BlocProvider(
                  create: (context) => ShopProfileBloc(repository: context.read<ShopProfileRepository>())..add(LoadShopProfile()),
                ),
              ],
              child: const BottomNavbar(),
            );
          },
        ),
        GoRoute(
          path: '/shop/:shopId',
          name: 'shop',
          builder: (context, state) {
            final shopId = state.pathParameters['shopId'] ?? '';

            if (shopId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text("Shop not found. Invalid URL.")),
              );
            }

            // Set the shop ID for the customer's session based on the URL
            context.read<CategoryRepository>().setShopId(shopId);
            context.read<MenuRepository>().setShopId(shopId);
            context.read<ShopProfileRepository>().setShopId(shopId);
            context.read<OfferRepository>().setShopId(shopId);
            context.read<OfferBloc>().add(LoadOffers());

            return MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => CategoryBloc(repository: context.read<CategoryRepository>())..add(LoadCategories()),
                ),
                BlocProvider(
                  create: (context) => MenuBloc(repository: context.read<MenuRepository>())..add(LoadMenuItems()),
                ),
                BlocProvider(
                  create: (context) => ShopProfileBloc(repository: context.read<ShopProfileRepository>())..add(LoadShopProfile()),
                ),
              ],
              child: const CustomerBottomNavbar(),
            );
          },
        ),
        GoRoute(
          path: '/admin',
          name: 'admin',
          builder: (context, state) {
            final currentEmail = FirebaseAuth.instance.currentUser?.email;
            
            // Note: AdminPanel.adminEmail should be accessible, or we just hardcode it here. 
            // It's cleaner to access the constant if it's static.
            if (currentEmail == AdminPanel.adminEmail) {
              return const AdminPanel();
            } else {
              return const NotFoundPage();
            }
          },
        ),
      ],
    );
  }
}

/// A simple [Listenable] that triggers GoRouter to refresh whenever the AuthBloc state changes.
class AuthListenable extends ChangeNotifier {
  final AuthBloc authBloc;
  late final StreamSubscription _subscription;

  AuthListenable(this.authBloc) {
    _subscription = authBloc.stream.listen((state) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
