import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class QrGenerator {
  /// Loads the dummy QR code image from assets
  static Future<pw.MemoryImage> getDummyQrCode() async {
    final ByteData data = await rootBundle.load('assets/images/dummy_qr.png');
    final Uint8List bytes = data.buffer.asUint8List();
    return pw.MemoryImage(bytes);
  }
  
  /// Generates a placeholder QR code widget when the image is not available
  static pw.Widget getQrPlaceholder({double size = 100, String text = 'QR Code'}) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          // Grid pattern to simulate QR code
          pw.GridView(
            crossAxisCount: 5,
            childAspectRatio: 1,
            children: List.generate(25, (index) {
              // Create a pattern that looks like a QR code
              final bool isDark = index % 3 == 0 || index % 7 == 0 || index == 12;
              return pw.Container(
                color: isDark ? PdfColors.black : PdfColors.white,
                margin: const pw.EdgeInsets.all(1),
              );
            }),
          ),
          // Overlay text
          pw.Container(
            color: PdfColors.white.withOpacity(0.7),
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(
              text,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Generates a barcode placeholder
  static pw.Widget getBarcodePlaceholder({required String code, double height = 30}) {
    return pw.Container(
      height: height,
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
              height: isShort ? height * 0.6 : height * 0.8,
              color: PdfColors.black,
            );
          }),
          pw.SizedBox(width: 8),
          pw.Text(
            code,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }
}
