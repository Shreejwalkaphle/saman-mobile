import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../cart/cart_screen.dart';
import '../orders/order_list_screen.dart';
import 'shop_products_screen.dart';

class ShopListScreen extends StatefulWidget {
  const ShopListScreen({
    required this.api,
    required this.email,
    required this.onLogout,
    super.key,
  });

  final ApiClient api;
  final String email;
  final VoidCallback onLogout;

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  late Future<List<Map<String, dynamic>>> _shops;

  @override
  void initState() {
    super.initState();
    _shops = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await widget.api.get('/api/shops?size=50');
    return (response['content'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biratnagar Shops'),
        actions: [
          IconButton(
            tooltip: 'Orders',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => OrderListScreen(api: widget.api)),
            ),
          ),
          IconButton(
            tooltip: 'Cart',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartScreen(api: widget.api)),
            ),
          ),
          PopupMenuButton<void>(
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(widget.email)),
              PopupMenuItem(onTap: widget.onLogout, child: const Text('Logout')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shops,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              retry: () => setState(() => _shops = _load()),
            );
          }
          final shops = snapshot.data!;
          if (shops.isEmpty) return const Center(child: Text('अहिले active shop छैन।'));
          return RefreshIndicator(
            onRefresh: () async => setState(() => _shops = _load()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: shops.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final shop = shops[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(child: Icon(Icons.store)),
                    title: Text(shop['name'] as String),
                    subtitle: Text('${shop['addressLine1']}, ${shop['city']}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopProductsScreen(
                          api: widget.api,
                          shopId: shop['id'] as String,
                          shopName: shop['name'] as String,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: retry, child: const Text('Retry')),
          ]),
        ),
      );
}
