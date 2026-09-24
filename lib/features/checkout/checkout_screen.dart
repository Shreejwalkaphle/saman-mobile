import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/location_service.dart';
import '../../core/request_id.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    required this.api,
    required this.subtotal,
    super.key,
  });

  final ApiClient api;
  final num subtotal;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _locationService = LocationService();
  CustomerLocation? _location;
  Map<String, dynamic>? _quote;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _invalidateQuote() {
    if (_quote != null) setState(() => _quote = null);
  }

  Future<void> _useLocation() async {
    setState(() {
      _busy = true;
      _error = null;
      _quote = null;
    });
    try {
      final location = await _locationService.current();
      if (mounted) setState(() => _location = location);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      setState(() => _error = 'पहिले current location लिनुहोस्।');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _quote = null;
    });
    try {
      final quote = await widget.api.post('/api/delivery/quotes', body: {
        'latitude': _location!.latitude,
        'longitude': _location!.longitude,
        'city': 'Biratnagar',
        'district': 'Morang',
      });
      if (mounted) setState(() => _quote = quote);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _placeOrder() async {
    final quote = _quote;
    final location = _location;
    if (quote == null || location == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await widget.api.post(
        '/api/orders/checkout',
        headers: {'Idempotency-Key': newRequestId()},
        body: {
          'addressLine1': _address.text.trim(),
          'addressLine2': null,
          'city': 'Biratnagar',
          'district': 'Morang',
          'postalCode': null,
          'phone': _phone.text.trim(),
          'deliveryQuoteId': quote['id'],
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Order created'),
          content: Text('Order ${order['id']}\nTotal: NPR ${order['totalAmount']}'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _quote = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    final total = quote == null ? null : widget.subtotal + (quote['fee'] as num);
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery checkout')),
      body: Form(
        key: _formKey,
        onChanged: _invalidateQuote,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Delivery address'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Address चाहिन्छ' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Phone चाहिन्छ' : null,
            ),
            const SizedBox(height: 14),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.location_city),
              title: Text('Biratnagar, Morang'),
              subtitle: Text('Pilot delivery area: maximum 10 km from the shop'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _useLocation,
              icon: const Icon(Icons.my_location),
              label: Text(_location == null ? 'Use current location' : 'Refresh current location'),
            ),
            if (_location != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)}',
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: _busy ? null : _requestQuote,
              child: const Text('Calculate delivery'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (quote != null) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _PriceRow(label: 'Subtotal', value: widget.subtotal),
                    _PriceRow(label: 'Delivery (${quote['distanceKm']} km)', value: quote['fee'] as num),
                    const Divider(),
                    _PriceRow(label: 'Total', value: total!, emphasized: true),
                    const SizedBox(height: 8),
                    Text('Quote expires: ${quote['expiresAt']}'),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _placeOrder,
                icon: const Icon(Icons.lock_outline),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Place order'),
                ),
              ),
            ],
            if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.value, this.emphasized = false});
  final String label;
  final num value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: emphasized ? Theme.of(context).textTheme.titleMedium : null),
          Text('NPR $value', style: emphasized ? Theme.of(context).textTheme.titleMedium : null),
        ]),
      );
}
