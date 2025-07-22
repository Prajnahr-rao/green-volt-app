import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';

class BookingCancellationScreen extends StatefulWidget {
  final Booking booking;
  final Function(Booking) onCancellationConfirmed;

  const BookingCancellationScreen({
    Key? key,
    required this.booking,
    required this.onCancellationConfirmed,
  }) : super(key: key);

  @override
  _BookingCancellationScreenState createState() => _BookingCancellationScreenState();
}

class _BookingCancellationScreenState extends State<BookingCancellationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isProcessing = false;
  String _selectedReason = 'Change of plans';
  bool _acceptTerms = false;
  double _refundAmount = 0.0;

  final List<String> _cancellationReasons = [
    'Change of plans',
    'Found a better option',
    'Vehicle issue',
    'Weather conditions',
    'Emergency',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _calculateRefundAmount();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _calculateRefundAmount() {
    // Calculate time until booking
    final now = DateTime.now();
    final bookingDate = widget.booking.date;
    final bookingStartHour = widget.booking.startTime.hour;
    final bookingStartMinute = widget.booking.startTime.minute;

    final bookingDateTime = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      bookingStartHour,
      bookingStartMinute,
    );

    final difference = bookingDateTime.difference(now);
    final hoursUntilBooking = difference.inHours;

    // Refund policy:
    // > 24 hours: 100% refund
    // 12-24 hours: 75% refund
    // 1-12 hours: 50% refund
    // < 1 hour: 0% refund (cancellation not allowed)

    if (hoursUntilBooking > 24) {
      _refundAmount = widget.booking.cost;
    } else if (hoursUntilBooking > 12) {
      _refundAmount = widget.booking.cost * 0.75;
    } else if (hoursUntilBooking > 1) {
      _refundAmount = widget.booking.cost * 0.5;
    } else {
      _refundAmount = 0;
    }
  }

  Future<void> _processCancellation() async {
    if (!_formKey.currentState!.validate() || !_acceptTerms) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the cancellation terms'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Create a copy of the booking with updated status
      final cancelledBooking = Booking(
        id: widget.booking.id,
        stationId: widget.booking.stationId,
        stationName: widget.booking.stationName,
        vehicleId: widget.booking.vehicleId,
        vehicleName: widget.booking.vehicleName,
        date: widget.booking.date,
        startTime: widget.booking.startTime,
        endTime: widget.booking.endTime,
        chargerType: widget.booking.chargerType,
        chargerNumber: widget.booking.chargerNumber,
        cost: widget.booking.cost,
        status: 'Cancelled',
        vehicle: widget.booking.vehicle,
      );

      // Call the callback to update the booking
      widget.onCancellationConfirmed(cancelledBooking);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 10),
              const Text('Cancellation Successful'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your booking has been successfully cancelled.',
              ),
              const SizedBox(height: 16),
              if (_refundAmount > 0) ...[
                Text(
                  'Refund Amount: \$${_refundAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your refund will be processed within 3-5 business days.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
          actions: [
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingDate = DateFormat.yMMMMd().format(widget.booking.date);
    final startTime = _formatTimeOfDay(widget.booking.startTime);
    final endTime = _formatTimeOfDay(widget.booking.endTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancel Booking'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Top red background
          Container(
            height: 100,
            color: Colors.red,
          ),

          // Main content
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Booking details card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Booking Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              Icon(Icons.event_busy, color: Colors.red.shade800),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Booking details
                          _buildDetailRow(
                            'Booking ID',
                            widget.booking.id,
                            icon: Icons.confirmation_number,
                          ),

                          _buildDetailRow(
                            'Station',
                            widget.booking.stationName,
                            icon: Icons.ev_station,
                          ),

                          _buildDetailRow(
                            'Date',
                            bookingDate,
                            icon: Icons.calendar_today,
                          ),

                          _buildDetailRow(
                            'Time',
                            '$startTime - $endTime',
                            icon: Icons.access_time,
                          ),

                          _buildDetailRow(
                            'Amount Paid',
                            '\$${widget.booking.cost.toStringAsFixed(2)}',
                            icon: Icons.attach_money,
                            isHighlighted: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Refund information
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Refund Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                              Icon(Icons.monetization_on, color: Colors.red.shade800),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Refund amount
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _refundAmount > 0 ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _refundAmount > 0 ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _refundAmount > 0 ? Icons.check_circle : Icons.cancel,
                                      color: _refundAmount > 0 ? Colors.green.shade700 : Colors.red.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _refundAmount > 0
                                            ? 'Eligible for Refund'
                                            : 'Not Eligible for Refund',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _refundAmount > 0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_refundAmount > 0) ...[
                                  Text(
                                    'Refund Amount: \$${_refundAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Your refund will be processed to your original payment method within 3-5 business days.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ] else ...[
                                  const Text(
                                    'Cancellations less than 1 hour before the booking time are not eligible for a refund.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You can still cancel your booking if needed.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Cancellation reason
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason for Cancellation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dropdown for cancellation reason
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedReason,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Select a reason',
                              ),
                              items: _cancellationReasons.map((reason) {
                                return DropdownMenuItem(
                                  value: reason,
                                  child: Text(reason),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedReason = value!;
                                  if (value == 'Other') {
                                    _reasonController.clear();
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a reason';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Additional comments
                          if (_selectedReason == 'Other')
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextFormField(
                                controller: _reasonController,
                                decoration: const InputDecoration(
                                  labelText: 'Please specify',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                maxLines: 3,
                                validator: (value) {
                                  if (_selectedReason == 'Other' && (value == null || value.isEmpty)) {
                                    return 'Please provide details';
                                  }
                                  return null;
                                },
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Terms checkbox
                          CheckboxListTile(
                            title: const Text(
                              'I understand and accept the cancellation and refund policy',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            activeColor: Colors.red,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Cancel booking button
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _processCancellation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 2,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Cancel Booking',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Keep booking button
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Keep My Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
    return DateFormat.jm().format(dateTime);
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHighlighted ? Colors.red.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isHighlighted ? Colors.red.shade700 : Colors.grey.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontSize: isHighlighted ? 16 : 14,
              color: isHighlighted ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
