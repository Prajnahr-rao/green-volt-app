import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';
import '../models/payment_model.dart';
import '../models/payment_enums.dart';
import '../models/transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Custom formatter for credit card number input
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 16 digits
    if (value.length > 16) {
      value = value.substring(0, 16);
    }

    // Format with spaces after every 4 digits
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if ((i + 1) % 4 == 0 && i != value.length - 1) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Custom formatter for expiry date input
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String value = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 4 digits
    if (value.length > 4) {
      value = value.substring(0, 4);
    }

    // Format as MM/YY
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      if (i == 1 && i != value.length - 1) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final Function(double amount, String transactionId, String paymentMethod) onPaymentSuccess;
  final double initialAmount;
  final String? description;
  final String? stationId;
  final String? stationName;
  final String? productId;
  final String? productName;
  final String? serviceId;
  final String? serviceName;
  final TransactionType? transactionType;

  const PaymentScreen({
    Key? key,
    required this.onPaymentSuccess,
    this.initialAmount = 0.0,
    this.description,
    this.stationId,
    this.stationName,
    this.productId,
    this.productName,
    this.serviceId,
    this.serviceName,
    this.transactionType,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _amountController = TextEditingController();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.card;
  bool _shouldSavePaymentInfo = false;
  bool _isLoading = false;
  bool _hasStoredCard = false;
  Map<String, String>? _storedCardInfo;
  bool _hasStoredUpi = false;
  String _storedUpiId = '';

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.initialAmount.toStringAsFixed(2);
    _loadStoredCardInfo();
  }

  Future<void> _loadStoredCardInfo() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved card info
    final storedCard = prefs.getString('stored_card');
    if (storedCard != null) {
      setState(() {
        _storedCardInfo = Map<String, String>.from(json.decode(storedCard));
        _hasStoredCard = true;
        if (_storedCardInfo != null) {
          // Mask the card number for display (show only last 4 digits)
          String cardNumber = _storedCardInfo!['cardNumber'] ?? '';
          if (cardNumber.length >= 4) {
            String lastFour = cardNumber.substring(cardNumber.length - 4);
            _cardNumberController.text = '•••• •••• •••• $lastFour';
          } else {
            _cardNumberController.text = cardNumber;
          }

          _expiryDateController.text = _storedCardInfo!['expiryDate'] ?? '';
          _nameController.text = _storedCardInfo!['cardHolderName'] ?? '';

          // Pre-fill CVV field but leave it empty for security
          _cvvController.text = '';
        }
      });
    }

    // Load saved UPI ID
    final storedUpi = prefs.getString('stored_upi');
    if (storedUpi != null && storedUpi.isNotEmpty) {
      setState(() {
        _hasStoredUpi = true;
        _storedUpiId = storedUpi;
        _upiIdController.text = storedUpi;
      });
    }
  }

  Future<void> _savePaymentInfo() async {
    if (!_shouldSavePaymentInfo) return;

    final prefs = await SharedPreferences.getInstance();

    if (_selectedPaymentMethod == PaymentMethod.card) {
      // Save card information
      final cardInfo = {
        'cardNumber': _cardNumberController.text,
        'expiryDate': _expiryDateController.text,
        'cardHolderName': _nameController.text,
      };

      await prefs.setString('stored_card', json.encode(cardInfo));
    } else if (_selectedPaymentMethod == PaymentMethod.upi) {
      // Save UPI ID
      await prefs.setString('stored_upi', _upiIdController.text);
    }
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodOption(
                PaymentMethod.card,
                'Credit/Debit Card',
                Icons.credit_card,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodOption(
                PaymentMethod.upi,
                'UPI Payment',
                Icons.account_balance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodOption(
                PaymentMethod.cash,
                'Cash',
                Icons.payments,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey.shade700,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasStoredCard) ...[
          // Display saved card info
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Card header with gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.credit_card, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Saved Card',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            _hasStoredCard = false;
                            _cardNumberController.text = '';
                            _expiryDateController.text = '';
                            _nameController.text = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Card details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardInfoRow('Card Number', _cardNumberController.text),
                      _buildCardInfoRow('Expiry Date', _expiryDateController.text),
                      _buildCardInfoRow('Cardholder', _nameController.text),
                      const SizedBox(height: 16),

                      // CVV input
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: InputDecoration(
                            labelText: 'CVV (3 digits)',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            labelStyle: TextStyle(color: Colors.grey.shade700),
                            suffixIcon: const Icon(Icons.security, size: 20),
                            hintText: '123',
                          ),
                          validator: _validateCVV,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          obscureText: true,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Show full card form for new card entry
          const Text(
            'Enter Card Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Card number input
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number (16 digits)',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(color: Colors.grey.shade700),
                prefixIcon: const Icon(Icons.credit_card),
                hintText: 'XXXX XXXX XXXX XXXX',
              ),
              validator: _validateCardNumber,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Expiry date and CVV row
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date (MM/YY)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      labelStyle: TextStyle(color: Colors.grey.shade700),
                      prefixIcon: const Icon(Icons.date_range, size: 20),
                      hintText: 'MM/YY',
                    ),
                    validator: _validateExpiryDate,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV (3 digits)',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      labelStyle: TextStyle(color: Colors.grey.shade700),
                      prefixIcon: const Icon(Icons.security, size: 20),
                      hintText: '123',
                    ),
                    validator: _validateCVV,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    obscureText: true,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),

          // Cardholder name input
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(color: Colors.grey.shade700),
                prefixIcon: const Icon(Icons.person, size: 20),
              ),
              validator: _validateName,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // Save card checkbox
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade100),
            ),
            child: CheckboxListTile(
              title: const Text(
                'Save card information for future use',
                style: TextStyle(fontSize: 14),
              ),
              value: _shouldSavePaymentInfo,
              onChanged: (value) => setState(() => _shouldSavePaymentInfo = value ?? false),
              activeColor: Colors.green,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCardInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasStoredUpi) ...[
          // Display saved UPI info
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // UPI header with gradient
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.purple.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Saved UPI ID',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            _hasStoredUpi = false;
                            _upiIdController.text = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // UPI details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.account_balance_wallet, color: Colors.purple.shade700),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your UPI ID',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _upiIdController.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Show UPI form for new entry
          const Text(
            'Enter UPI Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // UPI ID input
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: _upiIdController,
              decoration: InputDecoration(
                labelText: 'UPI ID (e.g., name@upi)',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                labelStyle: TextStyle(color: Colors.grey.shade700),
                prefixIcon: const Icon(Icons.account_balance_wallet),
                hintText: 'yourname@bankname',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter UPI ID';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid UPI ID';
                }
                return null;
              },
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // UPI apps section
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular UPI Apps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildUpiAppIcon('Google Pay', Icons.g_mobiledata),
                    _buildUpiAppIcon('PhonePe', Icons.phone_android),
                    _buildUpiAppIcon('Paytm', Icons.payment),
                    _buildUpiAppIcon('BHIM', Icons.account_balance),
                  ],
                ),
              ],
            ),
          ),

          // Save UPI checkbox
          Container(
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade100),
            ),
            child: CheckboxListTile(
              title: const Text(
                'Save UPI ID for future use',
                style: TextStyle(fontSize: 14),
              ),
              value: _shouldSavePaymentInfo,
              onChanged: (value) => setState(() => _shouldSavePaymentInfo = value ?? false),
              activeColor: Colors.purple,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUpiAppIcon(String name, IconData icon) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.purple.shade700),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildCashPaymentInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cash header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Cash Payment',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Cash payment details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cash icon
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.attach_money,
                      color: Colors.orange.shade700,
                      size: 32,
                    ),
                  ),
                ),

                // Information text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cash Payment Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'You have selected to pay in cash. Please pay the amount at the venue when you arrive.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Your booking will be confirmed immediately, but payment will be collected on-site.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Payment steps
                Text(
                  'Payment Steps:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentStep(1, 'Arrive at the charging station'),
                _buildPaymentStep(2, 'Show your booking confirmation'),
                _buildPaymentStep(3, 'Pay the exact amount in cash'),
                _buildPaymentStep(4, 'Receive your receipt'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Top green background
          Container(
            height: 100,
            color: Colors.green,
          ),

          // Main content
          SingleChildScrollView(
            child: Column(
              children: [
                // Payment summary card
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
                              'Payment Summary',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Icon(Icons.receipt_long, color: Colors.green.shade800),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Payment details
                        _buildPaymentDetailRow(
                          'Amount to Pay',
                          '\$${_amountController.text}',
                          isHighlighted: true,
                        ),

                        if (widget.description != null)
                          _buildPaymentDetailRow('Description', widget.description!),

                        if (widget.stationName != null)
                          _buildPaymentDetailRow('Station', widget.stationName!),

                        if (widget.productName != null)
                          _buildPaymentDetailRow('Product', widget.productName!),

                        if (widget.serviceName != null)
                          _buildPaymentDetailRow('Service', widget.serviceName!),
                      ],
                    ),
                  ),
                ),

                // Payment method section
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment Method',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              Icon(Icons.payment, color: Colors.green.shade800),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Payment method selector
                          _buildPaymentMethodSelector(),
                          const SizedBox(height: 20),

                          // Payment form based on selected method
                          if (_selectedPaymentMethod == PaymentMethod.card)
                            _buildCardPaymentForm()
                          else if (_selectedPaymentMethod == PaymentMethod.upi)
                            _buildUpiPaymentForm()
                          else
                            _buildCashPaymentInfo(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pay button
                Container(
                  margin: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Proceed to Pay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Security note
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.grey.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your payment information is secure and encrypted.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
              color: isHighlighted ? Colors.green.shade800 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    // For card and UPI payment methods, validate the form
    if (_selectedPaymentMethod != PaymentMethod.cash) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isLoading = true);

    try {
      // Save payment information if requested
      if (_shouldSavePaymentInfo) {
        await _savePaymentInfo();
      }

      final paymentService = Provider.of<PaymentService>(context, listen: false);

      // Process payment based on selected method
      final result = await paymentService.processPayment(
        cardNumber: _selectedPaymentMethod == PaymentMethod.card ?
          (_hasStoredCard ? _storedCardInfo!['cardNumber'] : _cardNumberController.text) : null,
        expiryDate: _selectedPaymentMethod == PaymentMethod.card ?
          (_hasStoredCard ? _storedCardInfo!['expiryDate'] : _expiryDateController.text) : null,
        cvv: _selectedPaymentMethod == PaymentMethod.card ? _cvvController.text : null,
        name: _selectedPaymentMethod == PaymentMethod.card ?
          (_hasStoredCard ? _storedCardInfo!['cardHolderName'] : _nameController.text) : null,
        upiId: _selectedPaymentMethod == PaymentMethod.upi ? _upiIdController.text : null,
        amount: double.parse(_amountController.text),
        paymentMethod: _selectedPaymentMethod,
        description: widget.description ?? 'Payment',
        stationId: widget.stationId,
        stationName: widget.stationName,
        productId: widget.productId,
        productName: widget.productName,
        serviceId: widget.serviceId,
        serviceName: widget.serviceName,
        transactionType: widget.transactionType,
      );

      if (result['success']) {
        // Get payment method as string
        String paymentMethodStr = _selectedPaymentMethod.toString().split('.').last;

        // Call the success callback with payment details
        widget.onPaymentSuccess(
          result['amount'],
          result['transactionId'],
          paymentMethodStr,
        );

        // We don't need to pop here as the callback will handle navigation
        // The callback will navigate to payment confirmation screen
      } else {
        throw Exception(result['error'] ?? 'Payment failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    }
    if (value.length < 16) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
      return 'Format must be MM/YY';
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    }
    if (value.length < 3) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter cardholder name';
    }
    return null;
  }
}
