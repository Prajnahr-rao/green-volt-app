import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/receipt_service.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final double amount;
  final String transactionId;
  final DateTime paymentDate;
  final VoidCallback onContinue;
  final String? stationName;
  final String? serviceName;
  final String? productName;
  final String? paymentMethod;

  const PaymentConfirmationScreen({
    Key? key,
    required this.amount,
    required this.transactionId,
    required this.paymentDate,
    required this.onContinue,
    this.stationName,
    this.serviceName,
    this.productName,
    this.paymentMethod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final receiptService = ReceiptService();
    final primaryColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Top green background
          Container(
            height: 120,
            color: primaryColor,
          ),

          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                // Success card
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
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Success icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 80,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Success message
                        const Text(
                          'Payment Successful!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Your payment of \$${amount.toStringAsFixed(2)} has been processed successfully.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Animated checkmark
                        _buildAnimatedCheckmark(),
                      ],
                    ),
                  ),
                ),

                // Payment details card
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
                              'Payment Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor.shade800,
                              ),
                            ),
                            Icon(Icons.receipt_long, color: primaryColor.shade800),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Payment details
                        _buildDetailRow(
                          'Amount Paid',
                          '\$${amount.toStringAsFixed(2)}',
                          isHighlighted: true,
                          icon: Icons.attach_money,
                        ),

                        _buildDetailRow(
                          'Transaction ID',
                          transactionId,
                          icon: Icons.confirmation_number,
                        ),

                        _buildDetailRow(
                          'Date & Time',
                          DateFormat('MMM dd, yyyy - hh:mm a').format(paymentDate),
                          icon: Icons.access_time,
                        ),

                        _buildDetailRow(
                          'Payment Method',
                          _getPaymentMethodDisplay(),
                          icon: _getPaymentMethodIcon(),
                        ),

                        if (stationName != null)
                          _buildDetailRow(
                            'Station',
                            stationName!,
                            icon: Icons.ev_station,
                          ),

                        if (serviceName != null)
                          _buildDetailRow(
                            'Service',
                            serviceName!,
                            icon: Icons.miscellaneous_services,
                          ),

                        if (productName != null)
                          _buildDetailRow(
                            'Product',
                            productName!,
                            icon: Icons.shopping_bag,
                          ),
                      ],
                    ),
                  ),
                ),

                // Security note
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Transaction',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your payment information is encrypted and secure. A receipt has been sent to your email.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Continue button
                      ElevatedButton(
                        onPressed: onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Continue to Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Download receipt button
                      OutlinedButton(
                        onPressed: () async {
                          try {
                            await receiptService.generateAndShareReceipt(
                              amount: amount,
                              transactionId: transactionId,
                              paymentDate: paymentDate,
                              stationName: stationName,
                              serviceName: serviceName,
                              productName: productName,
                              paymentMethod: paymentMethod,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error generating receipt: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Download Receipt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Return to home button
                      TextButton(
                        onPressed: () {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text(
                          'Return to Home',
                          style: TextStyle(
                            fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildAnimatedCheckmark() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.verified,
          color: Colors.green.shade700,
          size: 40,
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon() {
    if (paymentMethod == null) {
      return Icons.credit_card;
    }

    switch (paymentMethod!.toLowerCase()) {
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

  String _getPaymentMethodDisplay() {
    if (paymentMethod == null) {
      return 'Credit Card';
    }

    switch (paymentMethod!.toLowerCase()) {
      case 'card':
        return 'Credit/Debit Card';
      case 'upi':
        return 'UPI Payment';
      case 'cash':
        return 'Cash (Pay on-site)';
      default:
        return paymentMethod!;
    }
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
                color: isHighlighted ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isHighlighted ? Colors.green.shade700 : Colors.grey.shade700,
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
              color: isHighlighted ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
