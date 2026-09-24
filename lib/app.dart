import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/shop/shop_list_screen.dart';

class SamanApp extends StatefulWidget {
  const SamanApp({this.api, super.key});

  final ApiClient? api;

  @override
  State<SamanApp> createState() => _SamanAppState();
}

class _SamanAppState extends State<SamanApp> {
  late final ApiClient _api;
  String? _email;
  bool _restoringSession = true;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiClient();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    String? email;
    try {
      email = await _api.restoreSession();
    } catch (_) {
      // A temporary network failure must not erase a valid refresh token. The
      // login screen remains available and the stored session can be retried on
      // the next app launch.
    }
    if (!mounted) return;
    setState(() {
      _email = email;
      _restoringSession = false;
    });
  }

  void _onAuthenticated(String email) {
    setState(() {
      _email = email;
    });
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    setState(() {
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
      home: _restoringSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _email == null
          ? LoginScreen(api: _api, onAuthenticated: _onAuthenticated)
          : ShopListScreen(api: _api, email: _email!, onLogout: _logout),
    );
  }
}
