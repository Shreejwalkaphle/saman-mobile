import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../cart/cart_screen.dart';

class ShopProductsScreen extends StatefulWidget {
  const ShopProductsScreen({
    required this.api,
    required this.shopId,
    required this.shopName,
    super.key,
  });

  final ApiClient api;
  final String shopId;
  final String shopName;

  @override
  State<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends State<ShopProductsScreen> {
  late Future<List<Map<String, dynamic>>> _products;
  String? _busyProduct;

  @override
  void initState() {
    super.initState();
    _products = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await widget.api.get('/api/products/shop/${widget.shopId}?size=50');
    return (response['content'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _add(Map<String, dynamic> product) async {
    setState(() => _busyProduct = product['id'] as String);
    try {
      await widget.api.post('/api/cart/items', body: {
        'productId': product['id'],
        'quantity': 1,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product['name']} cart मा थपियो')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busyProduct = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        actions: [
          IconButton(
            tooltip: 'Cart',
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartScreen(api: widget.api)),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final products = snapshot.data!;
          if (products.isEmpty) return const Center(child: Text('यो shop मा active product छैन।'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              final stock = product['stockQuantity'] as int;
              final id = product['id'] as String;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'] as String, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('NPR ${product['price']}'),
                          Text(stock > 0 ? '$stock available' : 'Out of stock'),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: stock == 0 || _busyProduct != null ? null : () => _add(product),
                      icon: _busyProduct == id
                          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_shopping_cart),
                      label: const Text('Add'),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
