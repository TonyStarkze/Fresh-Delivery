import 'package:delivery_webapp/data/repositories/auth_repository.dart';
import 'package:delivery_webapp/data/repositories/category_repository.dart';
import 'package:delivery_webapp/data/repositories/menu_repository.dart';
import 'package:delivery_webapp/data/repositories/shop_profile_repository.dart';
import 'package:delivery_webapp/data/repositories/offer_repository.dart';
import 'package:delivery_webapp/firebase_options.dart';
import 'package:delivery_webapp/logic/bloc/auth/auth_bloc.dart';
import 'package:delivery_webapp/logic/bloc/auth/auth_event.dart';
import 'package:delivery_webapp/logic/bloc/cart/cart_bloc.dart';
import 'package:delivery_webapp/logic/bloc/offer/offer_bloc.dart';
import 'package:delivery_webapp/presentation/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

void main() async {
  // Ensure that widget binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for the current platform (Web)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Initialize AuthBloc here so we can pass it to the Router
    _authBloc = AuthBloc(authRepository: AuthRepository())
      ..add(const AuthCheckRequested());

    _router = AppRouter.createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authBloc.authRepository),
        RepositoryProvider(create: (_) => CategoryRepository()),
        RepositoryProvider(create: (_) => MenuRepository()),
        RepositoryProvider(create: (_) => ShopProfileRepository()),
        RepositoryProvider(create: (_) => OfferRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider(create: (_) => CartBloc()),
          BlocProvider(create: (c) => OfferBloc(repository: c.read<OfferRepository>())),
        ],
        child: MaterialApp.router(
          title: 'Fresh Delivery',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
        ),
      ),
    );
  }
}
