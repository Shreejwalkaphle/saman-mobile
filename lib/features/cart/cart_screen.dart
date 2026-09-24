import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<Map<String, dynamic>> _cart;

  @override
  void initState() {
    super.initState();
    _cart = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    return (await widget.api.get('/api/cart')) as Map<String, dynamic>;
  }

  Future<void> _remove(String id) async {
    try {
      await widget.api.delete('/api/cart/items/$id');
      setState(() => _cart = _load());
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _cart,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final cart = snapshot.data!;
          final items = (cart['items'] as List<dynamic>).cast<Map<String, dynamic>>();
          if (items.isEmpty) return const Center(child: Text('Cart खाली छ।'));
          return Column(children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item['productName'] as String),
                    subtitle: Text('${item['quantity']} × NPR ${item['priceAtAddition']}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('NPR ${item['lineTotal']}'),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () => _remove(item['id'] as String),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ]),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Subtotal', style: Theme.of(context).textTheme.titleMedium),
                  Text('NPR ${cart['total']}', style: Theme.of(context).textTheme.titleLarge),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
