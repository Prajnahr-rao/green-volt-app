import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Only import dart:html if on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/booking.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter/services.dart';

class ReceiptService {
  /// Loads the company logo from assets
  Future<pw.MemoryImage?> _getLogoImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/icons/green_volt_logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Error loading logo: $e');
      return null;
    }
  }

  Future<void> generateAndShareReceipt({
    required double amount,
    required String transactionId,
    required DateTime paymentDate,
    String? stationName,
    String? serviceName,
    String? productName,
    String? paymentMethod,
  }) async {
    // Determine transaction type
    String transactionType = 'Purchase';
    PdfColor accentColor = PdfColors.green;

    if (stationName != null) {
      transactionType = 'Charging Session';
      accentColor = PdfColors.green;
    } else if (serviceName != null) {
      transactionType = 'Service Booking';
      accentColor = PdfColors.blue;
    } else if (productName != null) {
      transactionType = 'Product Purchase';
      accentColor = PdfColors.orange;
    }

    // Format payment method
    String formattedPaymentMethod = 'Credit Card (****1234)';
    if (paymentMethod != null) {
      switch (paymentMethod.toLowerCase()) {
        case 'card':
          formattedPaymentMethod = 'Credit/Debit Card (****1234)';
          break;
        case 'upi':
          formattedPaymentMethod = 'UPI Payment';
          break;
        case 'cash':
          formattedPaymentMethod = 'Cash (Pay on-site)';
          break;
        default:
          formattedPaymentMethod = paymentMethod;
      }
    }

    // Create PDF document
    final pdf = pw.Document();

    // Load logo image
    final logoImage = await _getLogoImage();

    // Add content to PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and company info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: accentColor),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Company logo
                    logoImage != null
                    ? pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: accentColor, width: 2),
                        ),
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Image(logoImage),
                      )
                    : pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: accentColor, width: 2),
                        ),
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                          child: pw.Text(
                            'GV',
                            style: pw.TextStyle(
                              color: accentColor,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Green Volt',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Your Trusted EV Charging Partner',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Receipt #${transactionId.substring(0, min(8, transactionId.length))}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: ${DateFormat('MMM dd, yyyy').format(paymentDate)}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          'Time: ${DateFormat('hh:mm a').format(paymentDate)}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Transaction Type Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  transactionType,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // Transaction Details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Transaction Details',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),

                    // Transaction specific details
                    if (stationName != null) _buildEnhancedDetailRow('Station', stationName),
                    if (serviceName != null) _buildEnhancedDetailRow('Service', serviceName),
                    if (productName != null) _buildEnhancedDetailRow('Product', productName),

                    _buildEnhancedDetailRow('Transaction ID', transactionId),
                    _buildEnhancedDetailRow('Date & Time', '${DateFormat('MMM dd, yyyy').format(paymentDate)} at ${DateFormat('hh:mm a').format(paymentDate)}'),
                    _buildEnhancedDetailRow('Payment Method', formattedPaymentMethod),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),

                    // Amount with larger font
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '\$${amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // QR Code and Barcode section
              pw.Row(
                children: [
                  // Simple QR code
                  pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    padding: const pw.EdgeInsets.all(10),
                    child: _buildSimpleQrCode(transactionId),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Scan to verify payment',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Use the Green Volt app to scan this QR code and verify the payment details.',
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        // Barcode placeholder
                        pw.Container(
                          height: 30,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              // Simulate barcode lines
                              ...List.generate(20, (index) {
                                final bool isThick = index % 3 == 0;
                                final bool isShort = index % 2 == 0;
                                return pw.Container(
                                  margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                                  width: isThick ? 2 : 1,
                                  height: isShort ? 20 : 25,
                                  color: PdfColors.black,
                                );
                              }),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                transactionId.substring(0, min(8, transactionId.length)),
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Footer with terms and contact
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Thank you for using Green Volt!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'For any questions or support, please contact us:',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Email: support@greenvolt.com | Phone: +1-800-GREEN-VOLT',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Terms & Conditions: This receipt is proof of payment. For refunds and cancellations, please refer to our policy on the website.',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      // Web: Trigger browser download
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'receipt_$transactionId.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop: Save PDF to temporary file and share
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/receipt_$transactionId.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Payment Receipt from Green Volt',
      );
    }
  }

  Future<void> generateAndDownloadBookingDetailsPdf({
    required Booking booking,
    String? stationAddress,
    String? paymentMethod,
    String? notes,
    List<Map<String, dynamic>>? orderItems,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    // Load logo image
    final logoImage = await _getLogoImage();
    String formatTimeOfDay(TimeOfDay tod) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
      return timeFormat.format(dt);
    }

    // Determine booking type and set appropriate colors
    bool isChargingBooking = booking.stationName.isNotEmpty && booking.stationName != 'Product Order';
    bool isProductOrder = booking.stationName == 'Product Order';

    PdfColor accentColor = isChargingBooking ? PdfColors.green : (isProductOrder ? PdfColors.orange : PdfColors.blue);
    String bookingType = isChargingBooking ? 'Charging Session' : (isProductOrder ? 'Product Order' : 'Service Booking');

    // Format payment method
    String formattedPaymentMethod = paymentMethod ?? 'Credit Card (****1234)';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with logo and company info
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: accentColor),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Company logo
                    logoImage != null
                    ? pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: accentColor, width: 2),
                        ),
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Image(logoImage),
                      )
                    : pw.Container(
                        width: 50,
                        height: 50,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: accentColor, width: 2),
                        ),
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Center(
                          child: pw.Text(
                            'GV',
                            style: pw.TextStyle(
                              color: accentColor,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Green Volt',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Your Trusted EV Charging Partner',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Booking #${booking.id.substring(0, min(8, booking.id.length))}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: ${dateFormat.format(booking.date)}',
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          'Status: ${booking.status}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: booking.status.toLowerCase() == 'confirmed' ? PdfColors.green : PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // Booking Type Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: pw.BoxDecoration(
                  color: accentColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  bookingType,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // Booking Details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Booking Details',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),

                    // Booking specific details
                    _buildEnhancedDetailRow('Booking ID', booking.id),
                    _buildEnhancedDetailRow('Status', booking.status),

                    if (isChargingBooking) ...[
                      _buildEnhancedDetailRow('Station', booking.stationName),
                      if (stationAddress != null && stationAddress.isNotEmpty)
                        _buildEnhancedDetailRow('Address', stationAddress),
                      _buildEnhancedDetailRow('Date', dateFormat.format(booking.date)),
                      _buildEnhancedDetailRow('Time', '${formatTimeOfDay(booking.startTime)} - ${formatTimeOfDay(booking.endTime)}'),
                      _buildEnhancedDetailRow('Duration', '${_durationString(booking.startTime, booking.endTime)}'),
                      _buildEnhancedDetailRow('Vehicle', booking.vehicleName),
                      _buildEnhancedDetailRow('Charger Type', booking.chargerType),
                      _buildEnhancedDetailRow('Charger Number', '#${booking.chargerNumber}'),
                    ],

                    _buildEnhancedDetailRow('Payment Method', formattedPaymentMethod),
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),

                    // Amount with larger font
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '\$${booking.cost.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Order Items Section (for product orders)
              if (isProductOrder && orderItems != null && orderItems.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Order Items',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 8),

                      // Table header
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                              'Item',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              'Qty',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'Price',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              'Total',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey300),

                      // Order items
                      ...orderItems.map((item) {
                        final name = item['name'] as String? ?? 'Unknown Item';
                        final price = item['price'] as double? ?? 0.0;
                        final quantity = item['quantity'] as int? ?? 1;
                        final isService = item['isService'] as bool? ?? false;
                        final total = price * quantity;

                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 5,
                                child: pw.Text(
                                  name,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: isService ? PdfColors.blue : PdfColors.black,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  isService ? '-' : quantity.toString(),
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  '\$${price.toStringAsFixed(2)}',
                                  style: const pw.TextStyle(
                                    fontSize: 10,
                                  ),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 4),

                      // Total
                      pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 8,
                            child: pw.Text(
                              'Total',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '\$${booking.cost.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                                color: accentColor,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Notes Section
              if (notes != null && notes.isNotEmpty) ...[
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Notes',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        notes,
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 24),

              // QR Code and Barcode section
              pw.Row(
                children: [
                  // Simple QR code
                  pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    padding: const pw.EdgeInsets.all(10),
                    child: _buildSimpleQrCode(booking.id),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Scan to verify booking',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Use the Green Volt app to scan this QR code and verify the booking details.',
                          style: const pw.TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        // Barcode placeholder
                        pw.Container(
                          height: 30,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              // Simulate barcode lines
                              ...List.generate(20, (index) {
                                final bool isThick = index % 3 == 0;
                                final bool isShort = index % 2 == 0;
                                return pw.Container(
                                  margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                                  width: isThick ? 2 : 1,
                                  height: isShort ? 20 : 25,
                                  color: PdfColors.black,
                                );
                              }),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                booking.id.substring(0, min(8, booking.id.length)),
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Footer with terms and contact
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Thank you for booking with Green Volt!',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'For any questions or support, please contact us:',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Email: support@greenvolt.com | Phone: +1-800-GREEN-VOLT',
                      style: const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Terms & Conditions: This document is proof of booking. For cancellations and refunds, please refer to our policy on the website.',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'booking_${booking.id}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/booking_${booking.id}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Booking Details from Green Volt',
      );
    }
  }

  String _durationString(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final diff = endMinutes - startMinutes;
    if (diff <= 0) return 'N/A';
    final hours = diff ~/ 60;
    final minutes = diff % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$minutes min';
    }
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEnhancedDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a simple QR code for the PDF
  pw.Widget _buildSimpleQrCode(String data) {
    // Create a simplified QR code pattern
    final int gridSize = 8;
    final List<bool> pattern = List.generate(gridSize * gridSize, (index) {
      // Create a deterministic pattern based on the data
      final int charCode = index < data.length ? data.codeUnitAt(index) : 0;
      return charCode % 3 == 0 || index % 7 == 0 || index == gridSize * gridSize ~/ 2;
    });

    return pw.GridView(
      crossAxisCount: gridSize,
      childAspectRatio: 1,
      children: List.generate(gridSize * gridSize, (index) {
        return pw.Container(
          color: pattern[index] ? PdfColors.black : PdfColors.white,
          margin: const pw.EdgeInsets.all(0.5),
        );
      }),
    );
  }
}