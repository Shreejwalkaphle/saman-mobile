import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/shop/shop_list_screen.dart';

class SamanApp extends StatefulWidget {
  const SamanApp({super.key});

  @override
  State<SamanApp> createState() => _SamanAppState();
}

class _SamanAppState extends State<SamanApp> {
  final ApiClient _api = ApiClient();
  String? _email;

  void _onAuthenticated(String token, String email) {
    setState(() {
      _api.token = token;
      _email = email;
    });
  }

  void _logout() {
    setState(() {
      _api.token = null;
      _email = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B6B53);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saman',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: _email == null
          ? LoginScreen(api: _api, onAuthenticated: _onAuthenticated)
          : ShopListScreen(api: _api, email: _email!, onLogout: _logout),
    );
  }
}
