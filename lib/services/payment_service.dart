import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_enums.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';

enum PaymentStatus {
  initial,
  loading,
  success,
  error
}

class PaymentService extends ChangeNotifier {
  PaymentStatus _status = PaymentStatus.initial;
  String? _error;
  static const double _processingFee = 2.50; // Fixed processing fee
  final BuildContext? context;

  PaymentService({this.context});

  PaymentStatus get status => _status;
  String? get error => _error;

  Future<Map<String, dynamic>> processPayment({
    String? cardNumber,
    String? expiryDate,
    String? cvv,
    String? name,
    String? upiId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? description,
    String? stationId,
    String? stationName,
    String? productId,
    String? productName,
    String? serviceId,
    String? serviceName,
    TransactionType? transactionType,
  }) async {
    try {
      _status = PaymentStatus.loading;
      notifyListeners();

      // Calculate total amount including processing fee
      final totalAmount = amount + _processingFee;

      // Generate transaction ID with prefix based on payment method
      String prefix = '';
      switch (paymentMethod) {
        case PaymentMethod.card:
          prefix = 'CARD';
          break;
        case PaymentMethod.upi:
          prefix = 'UPI';
          break;
        case PaymentMethod.cash:
          prefix = 'CASH';
          break;
      }

      String transactionId = '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

      // Simulate payment processing based on payment method
      switch (paymentMethod) {
        case PaymentMethod.card:
          // Validate card details (in a real app, this would call a payment gateway)
          if (paymentMethod == PaymentMethod.card &&
              (cardNumber == null || expiryDate == null || cvv == null || name == null)) {
            throw Exception('Invalid card details');
          }
          await Future.delayed(const Duration(seconds: 2));
          break;

        case PaymentMethod.upi:
          // Validate UPI ID (in a real app, this would call a UPI gateway)
          if (upiId == null || !upiId.contains('@')) {
            throw Exception('Invalid UPI ID');
          }
          await Future.delayed(const Duration(seconds: 1));
          break;

        case PaymentMethod.cash:
          // Cash payment doesn't need processing, just generate a reference
          await Future.delayed(const Duration(milliseconds: 500));
          break;
      }

      _status = PaymentStatus.success;
      notifyListeners();

      // Record transaction if context is available
      if (context != null) {
        // Determine transaction type based on parameters
        TransactionType txType = transactionType ??
          (stationId != null ? TransactionType.charging :
           productId != null ? TransactionType.product :
           serviceId != null ? TransactionType.service :
           TransactionType.charging);

        _recordTransaction(
          amount: totalAmount,
          transactionId: transactionId,
          paymentMethod: paymentMethod.toString().split('.').last,
          description: description ?? 'Payment processed',
          stationId: stationId,
          stationName: stationName,
          productId: productId,
          productName: productName,
          serviceId: serviceId,
          serviceName: serviceName,
          type: txType,
        );
      }

      // Return payment details
      return {
        'success': true,
        'transactionId': transactionId,
        'amount': totalAmount,
        'timestamp': DateTime.now().toIso8601String(),
        'paymentMethod': paymentMethod.toString().split('.').last,
        'processingFee': _processingFee,
      };
    } catch (e) {
      _status = PaymentStatus.error;
      _error = e.toString();
      notifyListeners();
      throw Exception('Payment failed: $e');
    }
  }

  // Record transaction in the transaction provider
  void _recordTransaction({
    required double amount,
    required String transactionId,
    required String paymentMethod,
    required String description,
    String? stationId,
    String? stationName,
    String? productId,
    String? productName,
    String? serviceId,
    String? serviceName,
    TransactionType type = TransactionType.charging,
  }) {
    if (context == null) return;

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context!, listen: false);

      final transaction = Transaction(
        id: transactionId,
        title: type == TransactionType.charging
            ? 'Charging Session'
            : type == TransactionType.product
                ? 'Product Purchase'
                : 'Service Booking',
        description: description,
        amount: amount,
        timestamp: DateTime.now(),
        type: type,
        status: TransactionStatus.completed,
        stationId: stationId,
        stationName: stationName,
        productId: productId,
        productName: productName,
        serviceId: serviceId,
        serviceName: serviceName,
        paymentMethod: paymentMethod,
        transactionReference: transactionId,
        isCredit: false,
      );

      transactionProvider.addTransaction(transaction);
    } catch (e) {
      print('Error recording transaction: $e');
    }
  }
}
