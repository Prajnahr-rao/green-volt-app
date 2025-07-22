import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/booking.dart';
import '../models/station.dart';
import '../models/vehicle.dart';
import '../services/receipt_service.dart';
import 'booking_cancellation_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  static const routeName = '/booking-confirmation';

  final Station station;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final int durationMinutes;
  final Vehicle vehicle;
  final String chargerType;
  final int chargerNumber;
  final String? paymentMethod;
  final String? transactionId;
  final double? amount; // Add payment amount

  const BookingConfirmationScreen({
    Key? key,
    required this.station,
    required this.selectedDate,
    required this.startTime,
    required this.durationMinutes,
    required this.vehicle,
    required this.chargerType,
    required this.chargerNumber,
    this.paymentMethod,
    this.transactionId,
    this.amount, // Add payment amount parameter
  }) : super(key: key);

  @override
  _BookingConfirmationScreenState createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late String _bookingId;
  late TimeOfDay _endTime;
  late double _estimatedCost;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Generate a random booking ID
    _bookingId = _generateBookingId();

    // Calculate end time
    final int endMinutes = widget.startTime.hour * 60 + widget.startTime.minute + widget.durationMinutes;
    _endTime = TimeOfDay(hour: endMinutes ~/ 60 % 24, minute: endMinutes % 60);

    // Use the actual payment amount if available, otherwise calculate estimated cost
    if (widget.amount != null) {
      _estimatedCost = widget.amount!;
    } else {
      // Calculate estimated cost as fallback
      final double ratePerHour = _getRateForChargerType(widget.chargerType);
      final double pricePerKwh = _extractPriceFromString(widget.station.price);
      final double estimatedKwh = _estimateKwhForDuration(widget.durationMinutes);

      // Calculate cost based on kWh if price is available, otherwise use rate per hour
      if (pricePerKwh > 0) {
        _estimatedCost = pricePerKwh * estimatedKwh;
      } else {
        _estimatedCost = ratePerHour * (widget.durationMinutes / 60);
      }
    }

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _generateBookingId() {
    final Random random = Random();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(6);
    final int randomPart = random.nextInt(9000) + 1000;
    return 'EV$timestamp$randomPart';
  }
  double _getRateForChargerType(String chargerType) {
    // Example rates per hour
    switch (chargerType) {
      case 'Fast Charger':
        return 15.0;
      case 'Super Charger':
        return 25.0;
      case 'Ultra Charger':
        return 35.0;
      default:
        return 10.0;
    }
  }

  double _extractPriceFromString(String priceString) {
    // Extract numeric value from price string like "$0.25/kWh"
    try {
      // Remove currency symbol, /kWh, and any whitespace
      final cleanedString = priceString.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanedString) ?? 0.0;
    } catch (e) {
      return 0.0; // Return 0 if parsing fails
    }
  }

  double _estimateKwhForDuration(int durationMinutes) {
    // Estimate kWh based on duration and vehicle battery capacity
    // This is a simplified calculation - in a real app, you would use more accurate models
    final batteryCapacity = double.tryParse(widget.vehicle.batteryCapacity) ?? 75.0;
    final chargingEfficiency = 0.85; // 85% charging efficiency

    // Estimate charging rate (% of battery per hour)
    double chargingRatePerHour;
    switch (widget.chargerType) {
      case 'Fast Charger':
        chargingRatePerHour = 0.5; // 50% per hour
        break;
      case 'Super Charger':
        chargingRatePerHour = 0.7; // 70% per hour
        break;
      case 'Ultra Charger':
        chargingRatePerHour = 0.9; // 90% per hour
        break;
      default:
        chargingRatePerHour = 0.3; // 30% per hour
    }

    // Calculate kWh for the duration
    final hours = durationMinutes / 60.0;
    final percentCharged = hours * chargingRatePerHour;
    final kwhCharged = (batteryCapacity * percentCharged * chargingEfficiency);

    return kwhCharged;
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat.jm().format(dateTime);
  }

  String _getPaymentMethodDisplay() {
    if (widget.paymentMethod == null) {
      return 'Credit Card';
    }

    switch (widget.paymentMethod!.toLowerCase()) {
      case 'card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI Payment';
      case 'cash':
        return 'Cash (Pay on-site)';
      default:
        return widget.paymentMethod!;
    }
  }

  IconData _getPaymentMethodIcon() {
    if (widget.paymentMethod == null) {
      return Icons.credit_card;
    }

    switch (widget.paymentMethod!.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.account_balance;
      case 'cash':
        return Icons.payments;
      default:
        return Icons.payment;
    }
  }

  Future<void> _confirmBooking() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Create booking object
    final booking = Booking(
      id: _bookingId,
      stationId: widget.station.id,
      stationName: widget.station.name,
      vehicleId: widget.vehicle.id,
      vehicleName: widget.vehicle.model,
      date: widget.selectedDate,
      startTime: widget.startTime,
      endTime: _endTime,
      chargerType: widget.chargerType,
      chargerNumber: widget.chargerNumber,
      cost: _estimatedCost,
      status: 'Confirmed',
    );

    // In a real app, you would save this booking to your database
    // bookingProvider.addBooking(booking);

    setState(() {
      _isLoading = false;
    });

    // Show confirmation dialog
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 10),
            const Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your booking has been confirmed. A confirmation has been sent to your email and mobile number.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Booking ID: $_bookingId',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate to bookings history page
              // Navigator.of(context).pushReplacementNamed('/bookings');
            },
            child: const Text('View My Bookings'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate back to home screen
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 28),
            const SizedBox(width: 10),
            const Text('Cancel Booking?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this booking?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cancellation Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• More than 24 hours: 100% refund\n• 12-24 hours: 75% refund\n• 1-12 hours: 50% refund\n• Less than 1 hour: No refund',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToCancellationScreen();
            },
            child: const Text('Proceed to Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToCancellationScreen() {
    // Create a booking object to pass to the cancellation screen
    final booking = Booking(
      id: _bookingId,
      stationId: widget.station.id,
      stationName: widget.station.name,
      vehicleId: widget.vehicle.id,
      vehicleName: widget.vehicle.model,
      date: widget.selectedDate,
      startTime: widget.startTime,
      endTime: _endTime,
      chargerType: widget.chargerType,
      chargerNumber: widget.chargerNumber,
      cost: _estimatedCost,
      status: 'Confirmed',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingCancellationScreen(
          booking: booking,
          onCancellationConfirmed: (cancelledBooking) {
            // In a real app, you would update the booking in your database
            // bookingProvider.updateBooking(cancelledBooking);

            // Show a snackbar to confirm cancellation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Booking cancelled successfully'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );

            // Navigate back to home screen
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  Booking get _currentBooking => Booking(
    id: _bookingId,
    stationId: widget.station.id,
    stationName: widget.station.name,
    vehicleId: widget.vehicle.id,
    vehicleName: widget.vehicle.model,
    date: widget.selectedDate,
    startTime: widget.startTime,
    endTime: _endTime,
    chargerType: widget.chargerType,
    chargerNumber: widget.chargerNumber,
    cost: _estimatedCost,
    status: 'Confirmed',
  );

  @override
  Widget build(BuildContext context) {
    final receiptService = ReceiptService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green.shade700),
                  const SizedBox(height: 16),
                  const Text('Processing your booking...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with station image
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        image: DecorationImage(
                          image: NetworkImage(widget.station.imageUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              widget.station.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.station.address,
                                    style: const TextStyle(color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Booking details
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Details',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Booking ID
                              _buildDetailRow(
                                icon: Icons.confirmation_number,
                                title: 'Booking ID',
                                value: _bookingId,
                                isHighlighted: true,
                              ),

                              // Date
                              _buildDetailRow(
                                icon: Icons.calendar_today,
                                title: 'Date',
                                value: DateFormat.yMMMMd().format(widget.selectedDate),
                              ),

                              // Time
                              _buildDetailRow(
                                icon: Icons.access_time,
                                title: 'Time',
                                value: '${_formatTimeOfDay(widget.startTime)} - ${_formatTimeOfDay(_endTime)}',
                              ),

                              // Duration
                              _buildDetailRow(
                                icon: Icons.timelapse,
                                title: 'Duration',
                                value: '${widget.durationMinutes} minutes',
                              ),

                              // Vehicle
                              _buildDetailRow(
                                icon: Icons.electric_car,
                                title: 'Vehicle',
                                value: '${widget.vehicle.make} ${widget.vehicle.model}',
                              ),

                              // Charger Type
                              _buildDetailRow(
                                icon: Icons.electrical_services,
                                title: 'Charger Type',
                                value: widget.chargerType,
                              ),

                              // Charger Number
                              _buildDetailRow(
                                icon: Icons.power,
                                title: 'Charger Number',
                                value: '#${widget.chargerNumber}',
                              ),

                              const Divider(),

                              // Cost
                              _buildDetailRow(
                                icon: Icons.attach_money,
                                title: 'Estimated Cost',
                                value: '\$${_estimatedCost.toStringAsFixed(2)}',
                                isHighlighted: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: [
                          // Download Booking PDF button
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                await receiptService.generateAndDownloadBookingDetailsPdf(
                                  booking: _currentBooking,
                                  stationAddress: widget.station.address,
                                  paymentMethod: _getPaymentMethodDisplay(),
                                  notes: '', // Add notes if available
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
                                  'Download Booking PDF',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Cancel Booking button
                          OutlinedButton(
                            onPressed: () {
                              _showCancellationDialog();
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(color: Colors.red.shade700),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cancel,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cancel Booking',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payment method
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Method',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(_getPaymentMethodIcon(), color: Colors.green.shade700),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getPaymentMethodDisplay(),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(widget.transactionId != null ? 'Transaction ID: ${widget.transactionId!.substring(0, min(widget.transactionId!.length, 10))}...' : ''),
                                    ],
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Notes
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notes',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: 'Add any special instructions or notes...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Cancellation policy
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 2,
                        color: Colors.amber.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                                                        children: [
                              Icon(Icons.info_outline, color: Colors.amber.shade800),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cancellation Policy',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Free cancellation up to 1 hour before the scheduled time. Late cancellations may incur a fee of 50% of the booking amount.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Confirm button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: _confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Cancel button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                    fontSize: isHighlighted ? 16 : 14,
                    color: isHighlighted ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

