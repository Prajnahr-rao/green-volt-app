import 'package:flutter/material.dart';
import 'dart:math';
import '../models/service.dart';
import '../services/receipt_service.dart';
import '../models/booking.dart';
import 'package:flutter/material.dart' show TimeOfDay;

class ServiceBookingConfirmationScreen extends StatefulWidget {
  final Service service;
  final double amount;
  final DateTime bookingDate;

  const ServiceBookingConfirmationScreen({
    Key? key,
    required this.service,
    required this.amount,
    required this.bookingDate,
  }) : super(key: key);

  @override
  _ServiceBookingConfirmationScreenState createState() => _ServiceBookingConfirmationScreenState();
}

class _ServiceBookingConfirmationScreenState extends State<ServiceBookingConfirmationScreen> {
  late String _bookingId;

  @override
  void initState() {
    super.initState();
    _bookingId = _generateBookingId();
  }

  String _generateBookingId() {
    final Random random = Random();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    final int randomPart = random.nextInt(9000) + 1000;
    return 'SV$timestamp$randomPart';
  }

  Booking get _serviceBooking => Booking(
    id: _bookingId,
    stationId: '',
    stationName: widget.service.name,
    vehicleId: '',
    vehicleName: '',
    date: widget.bookingDate,
    startTime: TimeOfDay(hour: 0, minute: 0),
    endTime: TimeOfDay(hour: 0, minute: 0),
    chargerType: '',
    chargerNumber: 0,
    cost: widget.amount,
    status: 'Confirmed',
  );

  @override
  Widget build(BuildContext context) {
    final receiptService = ReceiptService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Booking Confirmation'),
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
              'Booking Confirmed!',
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
                    Text('Service: ${widget.service.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Description: ${widget.service.description}'),
                    const SizedBox(height: 8),
                    Text('Booking ID: $_bookingId', style: TextStyle(color: Colors.green.shade700)),
                    const SizedBox(height: 8),
                    Text('Amount Paid: \$${widget.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    Text('Date: ${widget.bookingDate.toLocal()}'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await receiptService.generateAndDownloadBookingDetailsPdf(
                      booking: _serviceBooking,
                      stationAddress: '',
                      paymentMethod: 'Credit Card (****1234)',
                      notes: widget.service.description,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error generating booking PDF: ${e.toString()}'),
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
                      'Download Booking PDF',
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