import 'payment_enums.dart';

class PaymentModel {
  final String? cardNumber;
  final String? expiryDate;
  final String? cvv;
  final String? cardHolderName;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? upiId;

  PaymentModel({
    this.cardNumber,
    this.expiryDate,
    this.cvv,
    this.cardHolderName,
    required this.amount,
    required this.paymentMethod,
    this.upiId,
  });
}
