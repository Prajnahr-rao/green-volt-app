import 'package:flutter/material.dart';
import 'dart:math';
import '../services/receipt_service.dart';
import '../models/booking.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double amount;
  final DateTime orderDate;

  const OrderConfirmationScreen({
    Key? key,
    required this.cartItems,
    required this.amount,
    required this.orderDate,
  }) : super(key: key);

  @override
  _OrderConfirmationScreenState createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  late String _orderId;

  @override
  void initState() {
    super.initState();
    _orderId = _generateOrderId();

    // Reduce stock for purchased products
    _updateProductStock();
  }

  void _updateProductStock() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Process each cart item
    for (var item in widget.cartItems) {
      // Only process products (not services)
      if (item['isService'] != true && item['id'] != null) {
        final productId = item['id'];
        final purchasedQuantity = item['quantity'] ?? 1;

        // Get current product from provider
        final productIndex = adminProvider.getProducts.indexWhere((p) => p.id == productId);

        if (productIndex != -1) {
          final product = adminProvider.getProducts[productIndex];
          final newStockQuantity = product.stockQuantity - purchasedQuantity;

          // Update stock (ensure it doesn't go below 0)
          adminProvider.updateProductStock(
            productId,
            newStockQuantity > 0 ? newStockQuantity.toInt() : 0
          );
        }
      }
    }
  }

  String _generateOrderId() {
    final Random random = Random();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    final int randomPart = random.nextInt(9000) + 1000;
    return 'OD$timestamp$randomPart';
  }

  Booking get _orderBooking => Booking(
    id: _orderId,
    stationId: '',
    stationName: 'Product Order',
    vehicleId: '',
    vehicleName: '',
    date: widget.orderDate,
    startTime: TimeOfDay(hour: 0, minute: 0),
    endTime: TimeOfDay(hour: 0, minute: 0),
    chargerType: '',
    chargerNumber: 0,
    cost: widget.amount,
    status: 'Confirmed',
  );

  String get _productListNotes => widget.cartItems.map((item) => '- \\${item['name']} (x\\${item['quantity']})').join('\\n');

  @override
  Widget build(BuildContext context) {
    final receiptService = ReceiptService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmation'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'Order Placed!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade700),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order ID: $_orderId', style: TextStyle(color: Colors.green.shade700)),
                    const SizedBox(height: 8),
                    Text('Amount Paid: \$${widget.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Date: ${widget.orderDate.toLocal()}'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...widget.cartItems.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Icon(
                            item['isService'] == true ? Icons.build : Icons.shopping_bag,
                            size: 16,
                            color: item['isService'] == true ? Colors.blue : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item['name']} ${item['isService'] == true ? '' : 'x${item['quantity']}'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: item['isService'] == true ? Colors.blue.shade700 : Colors.orange.shade700,
                              ),
                            ),
                          ),
                          Text(
                            '\$${(item['price'] * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            // Download Booking PDF button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await receiptService.generateAndDownloadBookingDetailsPdf(
                      booking: _orderBooking,
                      stationAddress: '',
                      paymentMethod: 'Credit Card (****1234)',
                      notes: _productListNotes,
                      orderItems: widget.cartItems,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error generating booking PDF: \\${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: Colors.green.shade700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Download Order Details',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Navigate back to the home screen by popping until we reach it
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}