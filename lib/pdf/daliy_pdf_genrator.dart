import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class PdfGenerated {
  final Color kHeaderTop = const Color(0xFF0055D0);
  final Color kHeaderBottom = const Color(0xFF1A75FF);
  final Color kGreen = const Color(0xFF1B8F3A);
  final Color kLabelText = const Color(0xFF8A8A8A);
  final Color kValueText = const Color(0xFF0B0B0B);
  final currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  Future<String> generatePdf({
    required String userName,
    required String shareName,
    required String productType,
    required String exitDate,
    required String customerId,
    required String executedPrice,
    required String qty,
    required String avgBuyPrice,
    required String exitPrice,
    required String brokerage,
    required double realisedPL,
  }) async {
    try {
      // Validate required inputs
      if (userName.trim().isEmpty) {
        throw Exception("User name cannot be empty");
      }
      if (shareName.trim().isEmpty) {
        throw Exception("Share name cannot be empty");
      }
      if (customerId.trim().isEmpty) {
        throw Exception("Customer ID cannot be empty");
      }
      if (exitDate.trim().isEmpty) {
        throw Exception("Exit date cannot be empty");
      }

      // Validate numeric inputs
      final execPrice = double.tryParse(executedPrice.replaceAll(",", "")) ?? 0.0;
      final quantity = double.tryParse(qty.replaceAll(",", "")) ?? 0.0;
      final avgPrice = double.tryParse(avgBuyPrice.replaceAll(",", "")) ?? 0.0;
      final exitP = double.tryParse(exitPrice.replaceAll(",", "")) ?? 0.0;
      final broker = double.tryParse(brokerage.replaceAll(",", "")) ?? 0.0;

      if (execPrice < 0 || quantity < 0 || avgPrice < 0 || exitP < 0 || broker < 0) {
        throw Exception("Numeric values cannot be negative");
      }

      // Validate realisedPL is finite
      if (!realisedPL.isFinite) {
        throw Exception("Realised P/L value is invalid");
      }

      final pdfDoc = pw.Document();

      // Convert color values
      pdf.PdfColor pdfHeaderTop = pdf.PdfColor.fromInt(kHeaderTop.value);
      pdf.PdfColor pdfHeaderBottom = pdf.PdfColor.fromInt(kHeaderBottom.value);
      pdf.PdfColor pdfGreen = pdf.PdfColor.fromInt(kGreen.value);
      pdf.PdfColor pdfLabel = pdf.PdfColor.fromInt(kLabelText.value);
      pdf.PdfColor pdfValue = pdf.PdfColor.fromInt(kValueText.value);
      final pdfWhite = pdf.PdfColor.fromHex("#FFFFFF");

      // Load fonts with error handling
      pw.Font ttfRegular;
      pw.Font ttfBold;
      
      try {
        final fontRegularData = await rootBundle.load(
          "assets/fonts/NotoSans-Regular.ttf",
        );
        ttfRegular = pw.Font.ttf(fontRegularData);
      } catch (e) {
        throw Exception("Failed to load regular font: $e");
      }

      try {
        final fontBoldData = await rootBundle.load(
          "assets/fonts/NotoSans-Bold.ttf",
        );
        ttfBold = pw.Font.ttf(fontBoldData);
      } catch (e) {
        throw Exception("Failed to load bold font: $e");
      }
    pdfDoc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            color: pdf.PdfColor.fromHex("#F0F0F0"),
            child: pw.Center(
              child: pw.Container(
                width: 380,
                decoration: pw.BoxDecoration(
                  color: pdf.PdfColor.fromHex('#FFFFFF'),
                  borderRadius: pw.BorderRadius.circular(18),
                ),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min, // IMPORTANT
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    /// ------- HEADER -------
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(18),
                          topRight: pw.Radius.circular(18),
                        ),
                        gradient: pw.LinearGradient(
                          begin: pw.Alignment.centerLeft,
                          end: pw.Alignment.centerRight,
                          colors: [pdfHeaderTop, pdfHeaderBottom],
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "ABBOT Wealth Management",
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: ttfBold,
                                  color: pdfWhite,
                                ),
                              ),
                              pw.Text(
                                "Ltd.",
                                style: pw.TextStyle(
                                  fontSize: 16,
                                  font: ttfBold,
                                  color: pdfWhite,
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                "Trade Exit Receipt",
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  font: ttfRegular,
                                  color: pdfWhite,
                                ),
                              ),
                            ],
                          ),
                          pw.Text(
                            "User: $userName",
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 11,
                              font: ttfRegular,
                              color: pdfWhite,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 18),

                    /// ------- TITLE -------
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(horizontal: 18),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            shareName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 18,
                              font: ttfBold,
                              color: pdfValue,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            "Exit (${productType.toUpperCase()})",
                            style: pw.TextStyle(
                              fontSize: 12,
                              font: ttfRegular,
                              color: pdfLabel,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 14),
                    _divider(),
                    pw.SizedBox(height: 14),

                    /// ------- CHIPS -------
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(horizontal: 18),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _pdfDetailChip(
                            "Exit Date",
                            exitDate,
                            ttfRegular,
                            ttfBold,
                          ),
                          _pdfDetailChip(
                            "Customer ID",
                            customerId,
                            ttfRegular,
                            ttfBold,
                          ),
                          _pdfDetailChip(
                            "Executed Price",
                            currency.format(
                              double.tryParse(
                                    executedPrice.replaceAll(",", ""),
                                  ) ??
                                  0,
                            ),
                            ttfRegular,
                            ttfBold,
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 14),
                    _divider(),
                    pw.SizedBox(height: 10),

                    /// ------- DETAILS -------
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(horizontal: 18),
                      child: pw.Column(
                        children: [
                          _row(
                            "ProductType:",
                            productType,
                            ttfRegular,
                            ttfBold,
                          ),
                          _row("Quantity:", qty, ttfRegular, ttfBold),
                          _row(
                            "Avg. Buy Price:",
                            currency.format(
                              double.tryParse(
                                    avgBuyPrice.replaceAll(',', ''),
                                  ) ??
                                  0,
                            ),
                            ttfRegular,
                            ttfBold,
                          ),
                          _row(
                            "Exit Price:",
                            currency.format(
                              double.tryParse(exitPrice.replaceAll(',', '')) ??
                                  0,
                            ),
                            ttfRegular,
                            ttfBold,
                          ),
                          _row(
                            "Brokerage:",
                            currency.format(
                              double.tryParse(brokerage.replaceAll(',', '')) ??
                                  0,
                            ),
                            ttfRegular,
                            ttfBold,
                          ),
                          _row(
                            "Realised P&L:",
                            realisedPL >= 0
                                ? " +${currency.format(realisedPL.abs())}"
                                : "-${currency.format(realisedPL.abs())}",
                            ttfRegular,
                            ttfBold,
                            highlight: false,
                            profitColor: realisedPL >= 0
                                ? pdfGreen
                                : pdf.PdfColor.fromHex("#FF0000"),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 22),

                    /// ------- AMOUNT BOX -------
                    pw.Padding(
                      padding: pw.EdgeInsets.symmetric(horizontal: 18),
                      child: pw.Container(
                        width: double.infinity,
                        padding: pw.EdgeInsets.symmetric(vertical: 14),
                        decoration: pw.BoxDecoration(
                          color: realisedPL >= 0
                              ? pdfGreen
                              : pdf.PdfColor.fromHex("#FF0000"),
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              realisedPL >= 0
                                  ? "Net Amount Received:"
                                  : "Net Amount Lost:",
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 14,
                                color: pdfWhite,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              realisedPL >= 0
                                  ? "+${currency.format(realisedPL.abs())}"
                                  : "-${currency.format(realisedPL.abs())}",
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 20,
                                color: pdfWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 20),

                    /// ------- FOOTER -------
                    pw.Center(
                      child: pw.Container(
                        width: 380,
                        height: 52,
                        decoration: pw.BoxDecoration(
                          color: pdf.PdfColor.fromHex("#F2F2F2"),
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            "© ABBOT Wealth Management Ltd.",
                            style: pw.TextStyle(
                              fontSize: 10,
                              font: ttfRegular,
                              color: pdfLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

      final Uint8List bytes = await pdfDoc.save();

      // Validate bytes
      if (bytes.isEmpty) {
        throw Exception("PDF bytes are empty - generation failed");
      }

      // Get appropriate directory for saving PDF
      Directory downloadsDir;

      try {
        if (Platform.isAndroid) {
          // Try to use Downloads folder first
          try {
            downloadsDir = Directory('/storage/emulated/0/Download');
            // Check if directory exists and is accessible
            if (await downloadsDir.exists()) {
              // Test write access
              final testFile = File('${downloadsDir.path}/.test_write');
              try {
                await testFile.writeAsString('test');
                await testFile.delete();
              } catch (e) {
                // No write access, use app documents
                downloadsDir = await getApplicationDocumentsDirectory();
              }
            } else {
              downloadsDir = await getApplicationDocumentsDirectory();
            }
          } catch (e) {
            // Fallback to app documents directory
            downloadsDir = await getApplicationDocumentsDirectory();
          }
        } else if (Platform.isIOS) {
          // iOS: Use app documents directory
          downloadsDir = await getApplicationDocumentsDirectory();
        } else {
          // Other platforms
          downloadsDir = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        // Final fallback to app documents directory
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (!await downloadsDir.exists()) {
        try {
          await downloadsDir.create(recursive: true);
        } catch (e) {
          throw Exception("Failed to create directory: $e");
        }
      }

      // Sanitize customer ID for filename
      final sanitizedCustomerId = customerId.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          "${downloadsDir.path}/exit_receipt_${sanitizedCustomerId}_$timestamp.pdf";

      final file = File(filePath);

      try {
        // Write PDF
        await file.writeAsBytes(bytes);

        // Verify file was created
        if (!await file.exists()) {
          throw Exception("PDF file was not created successfully");
        }

        // Verify file size
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception("PDF file is empty");
        }

        // Try to open the file (optional, don't fail if it doesn't work)
        try {
          await OpenFile.open(file.path);
        } catch (openError) {
          // If opening fails, still return the path - file is saved
          // Silently continue - file is saved successfully
        }

        return file.path;
      } catch (e) {
        throw Exception("Failed to save PDF locally: $e");
      }
    } catch (e) {
      throw Exception("Failed to generate PDF: $e");
    }
  }

  /// ----------- SMALL HELPERS -----------

  pw.Widget _divider() {
    return pw.Container(
      height: 1,
      color: pdf.PdfColor.fromHex("#DDDDDD"),
      width: 380,
    );
  }

  pw.Widget _row(
    String label,
    String val,
    pw.Font r,
    pw.Font b, {
    bool highlight = false,
    pdf.PdfColor? profitColor,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(label, style: pw.TextStyle(font: b, fontSize: 12)),
          ),
          pw.Expanded(
            child: pw.Text(
              val,
              style: pw.TextStyle(
                font: highlight ? b : r,
                fontSize: 12,
                color:
                    profitColor ??
                    (highlight
                        ? pdf.PdfColor.fromHex("#008000")
                        : pdf.PdfColor.fromHex("#000000")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfDetailChip(
    String label,
    String value,
    pw.Font regular,
    pw.Font bold,
  ) {
    return pw.Container(
      width: 105,
      padding: pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: pdf.PdfColor.fromHex("#F4F6F9"),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: pdf.PdfColor.fromHex("#7A7A7A"),
              font: regular,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(value, style: pw.TextStyle(fontSize: 12, font: bold)),
        ],
      ),
    );
  }
}
