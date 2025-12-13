// invoice_pdf.dart
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class InvoicePdf {
  // Store the last saved file path
  static String? _lastSavedFilePath;

  // Get the last saved file path
  static String? getLastSavedFilePath() => _lastSavedFilePath;

  // MAIN: generate PDF bytes and save locally
  static Future<Uint8List> generate({
    String? invoiceNo,
    required String date,
    required String idCode,
    required String name,
    required String phone,
    required String address,
    required List<Map<String, dynamic>> trades,
    required double totalPL,
  }) async {
    // Auto-generate invoice number if not provided
    final finalInvoiceNo = invoiceNo ?? generateInvoiceNumber();
    try {
      // Validate inputs
      if (trades.isEmpty) {
        throw Exception("Cannot generate PDF: No trades data provided");
      }

      // Validate required fields
      if (finalInvoiceNo.trim().isEmpty) {
        throw Exception("Invoice number cannot be empty");
      }
      if (date.trim().isEmpty) {
        throw Exception("Date cannot be empty");
      }
      if (idCode.trim().isEmpty) {
        throw Exception("Customer ID cannot be empty");
      }
      if (name.trim().isEmpty) {
        throw Exception("Customer name cannot be empty");
      }

      final doc = pw.Document();

      // Fonts - make sure these exist in assets and pubspec.yaml
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

      // Images (logo + stamp). If missing, catch and continue.
      pw.MemoryImage? logo;
      pw.MemoryImage? stamp;
      try {
        final logoData = (await rootBundle.load(
          "assets/logo.png",
        )).buffer.asUint8List();
        logo = pw.MemoryImage(logoData);
      } catch (_) {
        logo = null;
      }
      try {
        final stampData = (await rootBundle.load(
          "assets/ABBOTT.png",
        )).buffer.asUint8List();
        stamp = pw.MemoryImage(stampData);
      } catch (_) {
        stamp = null;
      }

      // Colors from screenshot
      final PdfColor headerCream = PdfColor.fromHex("#EFE7DA");
      final PdfColor subtleBorder = PdfColor.fromHex("#E0E0E0");

      // Number formatter
      final numF = NumberFormat("#,##0.00");

      doc.addPage(
      pw.MultiPage(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            pageFormat: PdfPageFormat.a4,
          ),
          build: (context) {
            return <pw.Widget>[
              // Header: centered logo (stamp in screenshot near top center)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [if (stamp != null) pw.Image(stamp, width: 240)],
              ),

              // Invoice number horizontally aligned right with small top strip
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // left empty so right aligns
                  pw.Expanded(child: pw.Container()),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                      pw.Container(
                        width: 260,
                        child: pw.Text(
                          "Invoice no. : $finalInvoiceNo",
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(font: ttfBold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Date stripe – cream colored bar with date text left
              pw.Container(
                color: headerCream,
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                child: pw.Row(
            children: [
                    pw.Text(
                      "Date : ",
                      style: pw.TextStyle(font: ttfBold, fontSize: 10),
                    ),
              pw.Text(
                      date,
                      style: pw.TextStyle(font: ttfRegular, fontSize: 10),
              ),
            ],
                ),
          ),

              // Customer info block (left) — mimic screenshot spacing
          pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                      "CUSTOMER ID : $idCode",
                      style: pw.TextStyle(font: ttfBold, fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "NAME : $name",
                      style: pw.TextStyle(font: ttfRegular, fontSize: 11),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "PHONE : $phone",
                      style: pw.TextStyle(font: ttfRegular, fontSize: 11),
                    ),
                    pw.SizedBox(height: 2),
                pw.Text(
                  "ADDRESS : $address",
                      style: pw.TextStyle(font: ttfRegular, fontSize: 11),
                ),
              ],
            ),
          ),

              pw.SizedBox(height: 12),

              // Table header - cream color bar as in screenshot
          pw.Container(
                decoration: pw.BoxDecoration(
                  color: headerCream,
                  border: pw.Border.all(color: subtleBorder, width: 0.5),
                ),
            child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                    _tableHeaderCell("SR", 30, ttfBold, pw.TextAlign.center),
                    _tableHeaderCell("DATE", 60, ttfBold, pw.TextAlign.left),
                    _tableHeaderCell("STOCK", 120, ttfBold, pw.TextAlign.left),
                    _tableHeaderCell(
                      "BUY (₹)",
                      60,
                      ttfBold,
                      pw.TextAlign.right,
                    ),
                    _tableHeaderCell(
                      "SELL (₹)",
                      60,
                      ttfBold,
                      pw.TextAlign.right,
                    ),
                    _tableHeaderCell("QTY", 35, ttfBold, pw.TextAlign.center),
                    _tableHeaderCell(
                      "BROKERAGE (₹)",
                      70,
                      ttfBold,
                      pw.TextAlign.right,
                    ),
                    _tableHeaderCell(
                      "P / L (₹)",
                      100,
                      ttfBold,
                      pw.TextAlign.right,
                    ),
              ],
            ),
          ),

              // Table body rows - All columns in one line
              pw.Column(
                children: trades.asMap().entries.map((entry) {
                  try {
                    final idx = entry.key;
                    final trade = entry.value;
                    final mapped = _mapTradeToOrder(trade, idx + 1);

                    // Safe P/L extraction
                    double pl = 0.0;
                    try {
                      final plValue = mapped['pl'];
                      if (plValue is num) {
                        pl = plValue.toDouble();
                      } else if (plValue != null) {
                        final plStr = plValue.toString().replaceAll(",", "").trim();
                        pl = double.tryParse(plStr) ?? 0.0;
                      }
                    } catch (_) {
                      pl = 0.0;
                    }

                    // Format P/L value - ensure proper formatting for large numbers
                    String plString = "";
                    try {
                      // Ensure pl is a valid number
                      if (pl.isNaN || !pl.isFinite) {
                        pl = 0.0;
                      }
                      
                      if (pl >= 0) {
                        plString = "₹${numF.format(pl.abs())}";
                      } else {
                        plString = "-₹${numF.format(pl.abs())}";
                      }
                      // Ensure string doesn't have extra spaces or newlines
                      plString = plString.replaceAll(RegExp(r'\s+'), ' ').trim();
                      // Ensure plString is not empty
                      if (plString.isEmpty) {
                        plString = pl >= 0 ? "₹0.00" : "-₹0.00";
                      }
                    } catch (e) {
                      plString = pl >= 0 ? "₹0.00" : "-₹0.00";
                    }
                    final plColor = pl >= 0 ? PdfColors.green : PdfColors.red;

                    // Safe numeric extraction for buy, sell, brokerage
                    double buyValue = 0.0;
                    try {
                      final buy = mapped['buy'];
                      if (buy is num) {
                        buyValue = buy.toDouble();
                      } else if (buy != null) {
                        buyValue = double.tryParse(buy.toString()) ?? 0.0;
                      }
                    } catch (_) {
                      buyValue = 0.0;
                    }

                    double sellValue = 0.0;
                    try {
                      final sell = mapped['sell'];
                      if (sell is num) {
                        sellValue = sell.toDouble();
                      } else if (sell != null) {
                        sellValue = double.tryParse(sell.toString()) ?? 0.0;
                      }
                    } catch (_) {
                      sellValue = 0.0;
                    }

                    double brokerageValue = 0.0;
                    try {
                      final brokerage = mapped['brokerage'];
                      if (brokerage is num) {
                        brokerageValue = brokerage.toDouble();
                      } else if (brokerage != null) {
                        brokerageValue =
                            double.tryParse(brokerage.toString()) ?? 0.0;
                      }
                    } catch (_) {
                      brokerageValue = 0.0;
                    }

                    return pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: subtleBorder,
                            width: 0.5,
                          ),
                          left: pw.BorderSide(color: subtleBorder, width: 0.5),
                          right: pw.BorderSide(color: subtleBorder, width: 0.5),
                        ),
                        color: idx % 2 == 0
                            ? PdfColors.white
                            : PdfColor.fromHex("#FAFBFF"),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // ORDER - Center aligned
                          _tableCell(
                            mapped['order']?.toString() ?? "",
                            30,
                            ttfRegular,
                            pw.TextAlign.center,
                          ),
                          // DATE - Left aligned
                          _tableCell(
                            mapped['date']?.toString() ?? "",
                            60,
                            ttfRegular,
                            pw.TextAlign.left,
                          ),
                          // STOCK - Left aligned
                          _tableCell(
                            mapped['stock']?.toString() ?? "",
                            120,
                            ttfRegular,
                            pw.TextAlign.left,
                          ),
                          // BUY - Right aligned
                          _tableCell(
                            "₹${numF.format(buyValue)}",
                            60,
                            ttfRegular,
                            pw.TextAlign.right,
                          ),
                          // SELL - Right aligned
                          _tableCell(
                            "₹${numF.format(sellValue)}",
                            60,
                            ttfRegular,
                            pw.TextAlign.right,
                          ),
                          // QTY - Center aligned
                          _tableCell(
                            mapped['qty']?.toString() ?? "0",
                            35,
                            ttfRegular,
                            pw.TextAlign.center,
                          ),
                          // BROKERAGE - Right aligned
                          _tableCell(
                            "₹${numF.format(brokerageValue)}",
                            70,
                            ttfRegular,
                            pw.TextAlign.right,
                          ),
                          // P/L - Right aligned with color - Ensure it displays
                          pw.Container(
                            width: 100,
                            constraints: pw.BoxConstraints(
                              maxWidth: 100,
                              minWidth: 100,
                            ),
                            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                left: pw.BorderSide(
                                  color: subtleBorder,
                                  width: 0.3,
                                ),
                              ),
                            ),
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                plString.isEmpty ? "₹0.00" : plString,
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                  font: ttfRegular,
                                  color: plColor,
                                  fontSize: 8,
                                ),
                                maxLines: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } catch (e) {
                    // Return empty container if trade mapping fails
                    return pw.Container(height: 0);
                  }
                }).toList(),
              ),

              pw.SizedBox(height: 14),

              // Margin row (cream little box)
          pw.Container(
                color: headerCream,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
            child: pw.Row(
              children: [
                pw.Text(
                  "Margin : ",
                      style: pw.TextStyle(font: ttfBold, fontSize: 11),
                  ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      "₹ 0.00",
                      style: pw.TextStyle(font: ttfRegular, fontSize: 11),
                ),
              ],
            ),
          ),

              pw.SizedBox(height: 18),

              // Terms left + stamp right (stamp is circular in screenshot)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
                  // Terms
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Term & Condition",
                          style: pw.TextStyle(font: ttfBold, fontSize: 12),
                    ),
                        pw.SizedBox(height: 6),
                  pw.Text(
                          "Note Detailed bill that records all transactions\nDone by broker on behalf of His client during a trading day",
                          style: pw.TextStyle(font: ttfRegular, fontSize: 10),
                  ),
                ],
              ),
                  ),

                  // Stamp/logo right
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      alignment: pw.Alignment.centerRight,
                      child: logo != null
                          ? pw.Image(logo, width: 140)
                          : pw.Container(),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Total band (left label, right amount)
          pw.Container(
                color: headerCream,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "TOTAL",
                      style: pw.TextStyle(font: ttfBold, fontSize: 13),
                ),
                pw.Text(
                      "₹${numF.format(totalPL.isFinite ? totalPL : 0.0)}",
                  style: pw.TextStyle(
                        font: ttfBold,
                        color: (totalPL.isFinite && totalPL >= 0)
                            ? PdfColors.green
                            : PdfColors.red,
                        fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

              // footer small spacing
              pw.SizedBox(height: 8),
            ];
          },
        ),
      );

      final bytes = await doc.save();

      // Automatically save PDF locally after generation
      try {
        _lastSavedFilePath = await _savePdfLocally(bytes, finalInvoiceNo, idCode);
        print("PDF saved locally at: $_lastSavedFilePath");
      } catch (saveError) {
        // Log error but don't fail the generation - bytes are still returned
        print("Warning: Failed to save PDF locally: $saveError");
        _lastSavedFilePath = null;
      }

      return bytes;
    } catch (e) {
      throw Exception("Failed to generate PDF: $e");
    }
  }

  // Internal method to save PDF locally
  static Future<String> _savePdfLocally(
    Uint8List bytes,
    String invoiceNo,
    String customerId,
  ) async {
    try {
      if (bytes.isEmpty) {
        throw Exception("PDF bytes are empty");
      }

      Directory directory;

      // Determine save directory
      try {
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          // Check if directory exists, if not use app documents
          if (!await directory.exists()) {
            directory = await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        // Fallback to app documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Sanitize filename
      final sanitizedId = customerId.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final sanitizedInvoice = invoiceNo.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          "invoice_${sanitizedId}_${sanitizedInvoice}_$timestamp.pdf";
      final filePath = "${directory.path}/$fileName";
      final file = File(filePath);

      // Write PDF to file
      await file.writeAsBytes(bytes);

      // Verify file was created
      if (!await file.exists()) {
        throw Exception("PDF file was not created successfully");
      }

      return filePath;
    } catch (e) {
      throw Exception("Failed to save PDF locally: $e");
    }
  }

  // Table header cell - Allow 2-3 lines for long headers
  static pw.Widget _tableHeaderCell(
    String text,
    double width,
    pw.Font font,
    pw.TextAlign align,
  ) {
    try {
      final borderColor = PdfColor.fromHex("#E0E0E0");
      // Clean header text but preserve spaces for word wrapping
      final cleanText = text
          .replaceAll('\r', ' ')
          .replaceAll('\t', ' ')
          .replaceAll(RegExp(r'\n+'), ' ')
          .trim();

    return pw.Container(
      width: width,
        constraints: pw.BoxConstraints(
          maxWidth: width,
          minWidth: width,
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: pw.Align(
          alignment: align == pw.TextAlign.center
              ? pw.Alignment.center
              : (align == pw.TextAlign.right
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft),
      child: pw.Text(
            cleanText.isEmpty ? " " : cleanText,
            textAlign: align,
            style: pw.TextStyle(font: font, fontSize: 9),
            maxLines: 3,
          ),
        ),
      );
    } catch (e) {
      // Return safe fallback container
      return pw.Container(
        width: width,
        constraints: pw.BoxConstraints(
          maxWidth: width,
          minWidth: width,
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: pw.Text(" ", style: pw.TextStyle(font: font, fontSize: 9)),
      );
    }
  }

  // Table data cell - Allow 2-3 lines for long values
  static pw.Widget _tableCell(
    String value,
    double width,
    pw.Font font,
    pw.TextAlign align,
  ) {
    try {
      final borderColor = PdfColor.fromHex("#E0E0E0");
      // Clean value but preserve spaces for word wrapping
      final cleanValue = value
          .replaceAll('\r', ' ')
          .replaceAll('\t', ' ')
          .replaceAll(RegExp(r'\n+'), ' ')
          .trim();

    return pw.Container(
        width: width,
        constraints: pw.BoxConstraints(
          maxWidth: width,
          minWidth: width,
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: pw.Align(
          alignment: align == pw.TextAlign.center
              ? pw.Alignment.center
              : (align == pw.TextAlign.right
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft),
          child: pw.Text(
            cleanValue.isEmpty ? " " : cleanValue,
            textAlign: align,
            style: pw.TextStyle(font: font, fontSize: 9),
            maxLines: 3,
          ),
        ),
      );
    } catch (e) {
      // Return safe fallback container
    return pw.Container(
      width: width,
        constraints: pw.BoxConstraints(
          maxWidth: width,
          minWidth: width,
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: pw.Text(" ", style: pw.TextStyle(font: font, fontSize: 9)),
      );
    }
  }

  // Map trade row to expected order entry (clean/robust)
  static Map<String, dynamic> _mapTradeToOrder(
    Map<String, dynamic> trade,
    int orderNumber,
  ) {
    try {
      // Date normalization - safe parsing
      String dateStr = "";
      try {
        final dateValue = trade["exit_date"];
        if (dateValue != null) {
          dateStr = dateValue.toString().trim();
          if (dateStr.isNotEmpty) {
            // if stored dd/MM/yyyy already - use as-is (take first 10)
            if (dateStr.contains('/') && dateStr.length >= 10) {
              dateStr = dateStr.substring(0, 10);
            } else if (dateStr.length >= 10) {
              try {
                final dt = DateTime.tryParse(dateStr.substring(0, 10));
                if (dt != null) {
                  dateStr = DateFormat("dd/MM/yyyy").format(dt);
                }
              } catch (_) {
                // Keep original date string if parsing fails
                dateStr = dateStr.length >= 10
                    ? dateStr.substring(0, 10)
                    : dateStr;
              }
            }
          }
        }
      } catch (_) {
        dateStr = "";
      }

      // Share name - safe extraction
      String share = "";
      try {
        share = (trade["share_name"]?.toString() ?? "").trim();
      } catch (_) {
        share = "";
      }

      // Product type - safe extraction
      String productType = "";
      try {
        productType = (trade["product_type"]?.toString() ?? "").trim();
      } catch (_) {
        productType = "";
      }

      final stockLabel = productType.isNotEmpty
          ? "$share (${productType.toLowerCase()})"
          : share;

      // Buy price - safe parsing
      double buy = 0.0;
      try {
        final buyValue = trade["avg_buy_price"];
        if (buyValue is num) {
          buy = buyValue.toDouble();
        } else if (buyValue != null) {
          final buyStr = buyValue.toString().replaceAll(",", "").trim();
          buy = double.tryParse(buyStr) ?? 0.0;
        }
      } catch (_) {
        buy = 0.0;
      }

      // Sell price - safe parsing
      double sell = 0.0;
      try {
        final sellValue = trade["exit_price"];
        if (sellValue is num) {
          sell = sellValue.toDouble();
        } else if (sellValue != null) {
          final sellStr = sellValue.toString().replaceAll(",", "").trim();
          sell = double.tryParse(sellStr) ?? 0.0;
        }
      } catch (_) {
        sell = 0.0;
      }

      // Brokerage - safe parsing
      double brokerage = 0.0;
      try {
        final brokerageValue = trade["brokerage"];
        if (brokerageValue is num) {
          brokerage = brokerageValue.toDouble();
        } else if (brokerageValue != null) {
          final brokerageStr = brokerageValue
              .toString()
              .replaceAll(",", "")
              .trim();
          brokerage = double.tryParse(brokerageStr) ?? 0.0;
        }
      } catch (_) {
        brokerage = 0.0;
      }

      // Quantity - safe parsing
      int qty = 0;
      try {
        final qtyValue = trade["qty"];
        if (qtyValue is num) {
          qty = qtyValue.toInt();
        } else if (qtyValue != null) {
          final qtyStr = qtyValue.toString().trim();
          qty = int.tryParse(qtyStr) ?? 0;
        }
      } catch (_) {
        qty = 0;
      }

      // P/L - safe parsing
      double pl = 0.0;
      try {
        final plValue = trade["realised_pl"];
        if (plValue is num) {
          pl = plValue.toDouble();
        } else if (plValue != null) {
          final plStr = plValue.toString().replaceAll(",", "").trim();
          pl = double.tryParse(plStr) ?? 0.0;
        }
      } catch (_) {
        pl = 0.0;
      }

      return {
        "order": orderNumber,
        "date": dateStr,
        "stock": stockLabel,
        "buy": buy,
        "sell": sell,
        "qty": qty,
        "brokerage": brokerage,
        "pl": pl,
      };
    } catch (e) {
      // Return safe defaults if mapping fails
      return {
        "order": orderNumber,
        "date": "",
        "stock": "",
        "buy": 0.0,
        "sell": 0.0,
        "qty": 0,
        "brokerage": 0.0,
        "pl": 0.0,
      };
    }
  }

  // Generate invoice number
  static String generateInvoiceNumber() {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final timestampStr = timestamp.toString();
      // Ensure we have enough digits
      if (timestampStr.length > 5) {
        return "In##${timestampStr.substring(timestampStr.length - 8)}";
      }
      return "In##$timestampStr";
    } catch (e) {
      // Fallback invoice number
      return "In##${DateTime.now().millisecondsSinceEpoch}";
    }
  }

  // Example helper to save bytes to file and return path (use from UI)
  static Future<String> savePdfBytes(
    Uint8List bytes, {
    String fileNamePrefix = "invoice",
  }) async {
    try {
      if (bytes.isEmpty) {
        throw Exception("PDF bytes are empty");
      }
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Sanitize filename prefix
      final sanitizedPrefix = fileNamePrefix.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final path = "${dir.path}/${sanitizedPrefix}_$timestamp.pdf";
      final file = File(path);

      // Ensure directory exists
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsBytes(bytes);
      return path;
    } catch (e) {
      throw Exception("Failed to save PDF file: $e");
    }
  }
}
