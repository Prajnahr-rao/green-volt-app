import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TransactionType {
  charging,
  product,
  service,
  refund,
  reward
}

enum TransactionStatus {
  completed,
  pending,
  failed,
  refunded
}

class Transaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime timestamp;
  final TransactionType type;
  final TransactionStatus status;
  final String? stationId;
  final String? stationName;
  final String? productId;
  final String? productName;
  final String? serviceId;
  final String? serviceName;
  final String paymentMethod;
  final String? transactionReference;
  final bool isCredit;

  Transaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.status,
    this.stationId,
    this.stationName,
    this.productId,
    this.productName,
    this.serviceId,
    this.serviceName,
    required this.paymentMethod,
    this.transactionReference,
    required this.isCredit,
  });

  // Get appropriate icon based on transaction type
  IconData get icon {
    switch (type) {
      case TransactionType.charging:
        return Icons.ev_station;
      case TransactionType.product:
        return Icons.shopping_bag;
      case TransactionType.service:
        return Icons.build;
      case TransactionType.refund:
        return Icons.replay;
      case TransactionType.reward:
        return Icons.card_giftcard;
    }
  }

  // Format amount with sign
  String get formattedAmount {
    return isCredit ? '+\$${amount.toStringAsFixed(2)}' : '-\$${amount.toStringAsFixed(2)}';
  }

  // Format date for display
  String get formattedDate {
    final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    return formatter.format(timestamp);
  }

  // Convert transaction to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
      'status': status.toString(),
      'stationId': stationId,
      'stationName': stationName,
      'productId': productId,
      'productName': productName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'paymentMethod': paymentMethod,
      'transactionReference': transactionReference,
      'isCredit': isCredit,
    };
  }

  // Create a transaction from a map (from storage)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      amount: map['amount'],
      timestamp: DateTime.parse(map['timestamp']),
      type: _parseTransactionType(map['type']),
      status: _parseTransactionStatus(map['status']),
      stationId: map['stationId'],
      stationName: map['stationName'],
      productId: map['productId'],
      productName: map['productName'],
      serviceId: map['serviceId'],
      serviceName: map['serviceName'],
      paymentMethod: map['paymentMethod'],
      transactionReference: map['transactionReference'],
      isCredit: map['isCredit'],
    );
  }

  // Helper method to parse transaction type from string
  static TransactionType _parseTransactionType(String typeStr) {
    switch (typeStr) {
      case 'TransactionType.charging':
        return TransactionType.charging;
      case 'TransactionType.product':
        return TransactionType.product;
      case 'TransactionType.service':
        return TransactionType.service;
      case 'TransactionType.refund':
        return TransactionType.refund;
      case 'TransactionType.reward':
        return TransactionType.reward;
      default:
        return TransactionType.charging;
    }
  }

  // Helper method to parse transaction status from string
  static TransactionStatus _parseTransactionStatus(String statusStr) {
    switch (statusStr) {
      case 'TransactionStatus.completed':
        return TransactionStatus.completed;
      case 'TransactionStatus.pending':
        return TransactionStatus.pending;
      case 'TransactionStatus.failed':
        return TransactionStatus.failed;
      case 'TransactionStatus.refunded':
        return TransactionStatus.refunded;
      default:
        return TransactionStatus.completed;
    }
  }
}
