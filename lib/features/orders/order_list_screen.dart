import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<List<Map<String, dynamic>>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final result = await widget.api.get('/api/orders');
    return (result as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _orders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
          final orders = snapshot.data!;
          if (orders.isEmpty) return const Center(child: Text('अहिलेसम्म order छैन।'));
          return RefreshIndicator(
            onRefresh: () async => setState(() => _orders = _load()),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final order = orders[index];
                final items = (order['items'] as List<dynamic>).cast<Map<String, dynamic>>();
                return Card(
                  child: ExpansionTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text('NPR ${order['totalAmount']}'),
                    subtitle: Text('${order['status']} • ${order['createdAt']}'),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      ...items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['productName'] as String),
                          trailing: Text('${item['quantity']} × NPR ${item['priceAtPurchase']}'),
                        ),
                      ),
                      const Divider(),
                      _OrderAmount(label: 'Subtotal', value: order['subtotalAmount']),
                      _OrderAmount(label: 'Delivery', value: order['deliveryFee']),
                      _OrderAmount(label: 'Total', value: order['totalAmount'], emphasized: true),
                      if (order['trackingNumber'] != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.local_shipping_outlined),
                          title: Text(order['trackingNumber'] as String),
                        ),
                    ],
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

class _OrderAmount extends StatelessWidget {
  const _OrderAmount({required this.label, required this.value, this.emphasized = false});
  final String label;
  final Object? value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: emphasized ? Theme.of(context).textTheme.titleMedium : null),
          Text('NPR $value', style: emphasized ? Theme.of(context).textTheme.titleMedium : null),
        ]),
      );
}
