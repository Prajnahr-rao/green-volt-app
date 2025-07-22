import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get transactions for the current month
  List<Transaction> get currentMonthTransactions {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _transactions.where((t) => t.timestamp.isAfter(startOfMonth)).toList();
  }

  // Get total spent this month
  double get totalSpentThisMonth {
    return currentMonthTransactions
        .where((t) => !t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get total spent on charging this month
  double get chargingSpentThisMonth {
    return currentMonthTransactions
        .where((t) => !t.isCredit && t.type == TransactionType.charging)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get total spent on products this month
  double get productsSpentThisMonth {
    return currentMonthTransactions
        .where((t) => !t.isCredit && t.type == TransactionType.product)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get total spent on services this month
  double get servicesSpentThisMonth {
    return currentMonthTransactions
        .where((t) => !t.isCredit && t.type == TransactionType.service)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // Get recent transactions (last 5)
  List<Transaction> get recentTransactions {
    final sorted = List<Transaction>.from(_transactions);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(5).toList();
  }

  // Initialize provider and load transactions
  Future<void> initialize() async {
    await loadTransactions();
  }

  // Load transactions from storage
  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getString('transactions');

      if (transactionsJson != null) {
        final List<dynamic> decodedList = json.decode(transactionsJson);
        _transactions = decodedList
            .map((item) => Transaction.fromMap(item))
            .toList();
      } else {
        // If no transactions exist, initialize with sample data
        _transactions = _getSampleTransactions();
        await saveTransactions();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save transactions to storage
  Future<void> saveTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = json.encode(
        _transactions.map((t) => t.toMap()).toList(),
      );
      await prefs.setString('transactions', transactionsJson);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Add a new transaction
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    notifyListeners();
    await saveTransactions();
  }

  // Add a charging transaction
  Future<void> addChargingTransaction({
    required String title,
    required String description,
    required double amount,
    required String stationId,
    required String stationName,
    required String paymentMethod,
    required String transactionReference,
    TransactionStatus status = TransactionStatus.completed,
  }) async {
    final transaction = Transaction(
      id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      timestamp: DateTime.now(),
      type: TransactionType.charging,
      status: status,
      stationId: stationId,
      stationName: stationName,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      isCredit: false,
    );

    await addTransaction(transaction);
  }

  // Add a pending charging transaction
  Future<void> addPendingChargingTransaction({
    required String title,
    required String description,
    required double amount,
    required String stationId,
    required String stationName,
    required String paymentMethod,
    required String transactionReference,
    DateTime? bookingDateTime,
  }) async {
    // If booking date/time is provided, include it in the description
    String updatedDescription = description;
    if (bookingDateTime != null) {
      final formattedDate = '${bookingDateTime.year}-'
          '${bookingDateTime.month.toString().padLeft(2, '0')}-'
          '${bookingDateTime.day.toString().padLeft(2, '0')} '
          '${bookingDateTime.hour.toString().padLeft(2, '0')}:'
          '${bookingDateTime.minute.toString().padLeft(2, '0')}';

      updatedDescription = '$description for $formattedDate';
    }

    await addChargingTransaction(
      title: title,
      description: updatedDescription,
      amount: amount,
      stationId: stationId,
      stationName: stationName,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      status: TransactionStatus.pending,
    );
  }

  // Add a product purchase transaction
  Future<void> addProductTransaction({
    required String title,
    required String description,
    required double amount,
    required String productId,
    required String productName,
    required String paymentMethod,
    required String transactionReference,
    TransactionStatus status = TransactionStatus.completed,
  }) async {
    final transaction = Transaction(
      id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      timestamp: DateTime.now(),
      type: TransactionType.product,
      status: status,
      productId: productId,
      productName: productName,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      isCredit: false,
    );

    await addTransaction(transaction);
  }

  // Add a pending product transaction
  Future<void> addPendingProductTransaction({
    required String title,
    required String description,
    required double amount,
    required String productId,
    required String productName,
    required String paymentMethod,
    required String transactionReference,
  }) async {
    await addProductTransaction(
      title: title,
      description: description,
      amount: amount,
      productId: productId,
      productName: productName,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      status: TransactionStatus.pending,
    );
  }

  // Add a service transaction
  Future<void> addServiceTransaction({
    required String title,
    required String description,
    required double amount,
    required String serviceId,
    required String serviceName,
    required String paymentMethod,
    required String transactionReference,
    TransactionStatus status = TransactionStatus.completed,
  }) async {
    final transaction = Transaction(
      id: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      timestamp: DateTime.now(),
      type: TransactionType.service,
      status: status,
      serviceId: serviceId,
      serviceName: serviceName,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      isCredit: false,
    );

    await addTransaction(transaction);
  }

  // Add a pending service transaction
  Future<void> addPendingServiceTransaction({
    required String title,
    required String description,
    required double amount,
    required String serviceId,
    required String serviceName,
    required String paymentMethod,
    required String transactionReference,
  }) async {
    await addServiceTransaction(
      title: title,
      description: description,
      amount: amount,
      serviceId: serviceId,
      serviceName: serviceName,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      status: TransactionStatus.pending,
    );
  }

  // Add a refund transaction
  Future<void> addRefundTransaction({
    required String title,
    required String description,
    required double amount,
    required String originalTransactionId,
    required String paymentMethod,
    String? productName,
    String? serviceName,
    String? stationName,
    String? productId,
    String? serviceId,
    String? stationId,
  }) async {
    // Find the original transaction to update its status
    final originalTransaction = _transactions.firstWhere(
      (t) => t.id == originalTransactionId,
      orElse: () => Transaction(
        id: 'UNKNOWN',
        title: 'Unknown Transaction',
        description: 'Unknown Transaction',
        amount: 0,
        timestamp: DateTime.now(),
        type: TransactionType.product,
        status: TransactionStatus.completed,
        paymentMethod: 'unknown',
        isCredit: false,
      ),
    );

    // If we found the original transaction, update its status to refunded
    if (originalTransaction.id != 'UNKNOWN') {
      final index = _transactions.indexWhere((t) => t.id == originalTransactionId);
      if (index != -1) {
        _transactions[index] = Transaction(
          id: originalTransaction.id,
          title: originalTransaction.title,
          description: originalTransaction.description,
          amount: originalTransaction.amount,
          timestamp: originalTransaction.timestamp,
          type: originalTransaction.type,
          status: TransactionStatus.refunded, // Update status to refunded
          paymentMethod: originalTransaction.paymentMethod,
          transactionReference: originalTransaction.transactionReference,
          isCredit: originalTransaction.isCredit,
          productId: originalTransaction.productId,
          productName: originalTransaction.productName,
          serviceId: originalTransaction.serviceId,
          serviceName: originalTransaction.serviceName,
          stationId: originalTransaction.stationId,
          stationName: originalTransaction.stationName,
        );
      }
    }

    // Create the refund transaction
    final transaction = Transaction(
      id: 'REF${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      timestamp: DateTime.now(),
      type: TransactionType.refund,
      status: TransactionStatus.completed,
      paymentMethod: paymentMethod,
      transactionReference: originalTransactionId,
      isCredit: true,
      productName: productName,
      serviceName: serviceName,
      stationName: stationName,
      productId: productId,
      serviceId: serviceId,
      stationId: stationId,
    );

    // Add the refund transaction
    _transactions.add(transaction);
    notifyListeners();
    await saveTransactions();
  }

  // Sample transactions for initial data
  List<Transaction> _getSampleTransactions() {
    final now = DateTime.now();

    return [
      // Completed transactions
      Transaction(
        id: 'TXN1001',
        title: 'Green Volt Station #1',
        description: 'Charging session at Green Volt Station #1',
        amount: 12.75,
        timestamp: DateTime(now.year, now.month, now.day - 2, 10, 45),
        type: TransactionType.charging,
        status: TransactionStatus.completed,
        stationId: '1',
        stationName: 'Green Volt Station #1',
        paymentMethod: 'card',
        transactionReference: 'CARD_123456789',
        isCredit: false,
      ),
      Transaction(
        id: 'TXN1002',
        title: 'EV Battery Purchase',
        description: 'Purchase of EV Battery',
        amount: 2.99,
        timestamp: DateTime(now.year, now.month, now.day - 5, 15, 20),
        type: TransactionType.product,
        status: TransactionStatus.completed,
        productId: 'P001',
        productName: 'EV Battery',
        paymentMethod: 'card',
        transactionReference: 'CARD_987654321',
        isCredit: false,
      ),
      Transaction(
        id: 'REF1001',
        title: 'Refund - Cancelled Booking',
        description: 'Refund for cancelled booking',
        amount: 8.50,
        timestamp: DateTime(now.year, now.month, now.day - 7, 9, 15),
        type: TransactionType.refund,
        status: TransactionStatus.completed,
        paymentMethod: 'card',
        transactionReference: 'TXN9876',
        isCredit: true,
      ),
      Transaction(
        id: 'TXN1003',
        title: 'City Center EV Hub',
        description: 'Charging session at City Center EV Hub',
        amount: 15.25,
        timestamp: DateTime(now.year, now.month, now.day - 9, 17, 30),
        type: TransactionType.charging,
        status: TransactionStatus.completed,
        stationId: '2',
        stationName: 'City Center EV Hub',
        paymentMethod: 'upi',
        transactionReference: 'UPI_123456789',
        isCredit: false,
      ),
      Transaction(
        id: 'REW1001',
        title: 'Monthly Reward Credit',
        description: 'Monthly reward for loyal customer',
        amount: 5.00,
        timestamp: DateTime(now.year, now.month, 1, 0, 0),
        type: TransactionType.reward,
        status: TransactionStatus.completed,
        paymentMethod: 'reward',
        transactionReference: 'REWARD_001',
        isCredit: true,
      ),

      // Pending transactions (for testing cancellation)
      Transaction(
        id: 'TXN1004',
        title: 'Upcoming Service Appointment',
        description: 'Battery health check and maintenance',
        amount: 49.99,
        timestamp: DateTime(now.year, now.month, now.day, 14, 30),
        type: TransactionType.service,
        status: TransactionStatus.pending,
        serviceId: 'S001',
        serviceName: 'Battery Health Check',
        paymentMethod: 'card',
        transactionReference: 'CARD_456789123',
        isCredit: false,
      ),
      Transaction(
        id: 'TXN1005',
        title: 'Scheduled Charging Session',
        description: 'Reserved charging slot at Riverside EV Station for ${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day + 1).toString().padLeft(2, '0')} 09:00',
        amount: 18.50,
        timestamp: DateTime(now.year, now.month, now.day, 10, 0),
        type: TransactionType.charging,
        status: TransactionStatus.pending,
        stationId: '3',
        stationName: 'Riverside EV Station',
        paymentMethod: 'upi',
        transactionReference: 'UPI_987654321',
        isCredit: false,
      ),

      // Add another station booking with a past time (for testing cancellation logic)
      Transaction(
        id: 'TXN1007',
        title: 'Expired Charging Session',
        description: 'Reserved charging slot at Downtown EV Hub for ${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day - 1).toString().padLeft(2, '0')} 14:30',
        amount: 22.75,
        timestamp: DateTime(now.year, now.month, now.day - 2, 10, 0),
        type: TransactionType.charging,
        status: TransactionStatus.pending,
        stationId: '4',
        stationName: 'Downtown EV Hub',
        paymentMethod: 'card',
        transactionReference: 'CARD_246813579',
        isCredit: false,
      ),
      Transaction(
        id: 'TXN1006',
        title: 'EV Accessory Order',
        description: 'Portable charger and cable organizer',
        amount: 34.95,
        timestamp: DateTime(now.year, now.month, now.day, 11, 45),
        type: TransactionType.product,
        status: TransactionStatus.pending,
        productId: 'P002',
        productName: 'Portable EV Charger Kit',
        paymentMethod: 'card',
        transactionReference: 'CARD_135792468',
        isCredit: false,
      ),
    ];
  }
}
