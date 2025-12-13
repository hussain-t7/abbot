import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:abbot/database/user_bd.dart';
import 'package:abbot/database/stock_bd.dart';
import 'package:abbot/pdf/last_7_days_pdf_genrator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final TextEditingController customerIdController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allCustomers = [];
  List<Map<String, dynamic>> filteredCustomers = [];

  Map<String, dynamic>? customer;
  List<Map<String, dynamic>> trades = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadAllCustomers();
  }

  @override
  void dispose() {
    customerIdController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadAllCustomers() async {
    allCustomers = await DatabaseHelper.instance.getAllCustomers();
    filteredCustomers = allCustomers;
    setState(() {});
  }

  Future<void> loadInvoiceData() async {
    final id = customerIdController.text.trim();

    if (id.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a Customer ID.")),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final c = await DatabaseHelper.instance.getCustomerById(id);
      final t = await TradeExitDB.instance.getLast7DaysTrades(id);

      if (mounted) {
        setState(() {
          customer = c;
          trades = t;
          loading = false;
        });

        if (c == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Customer ID not found!")),
          );
        } else if (t.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No trades found for this customer.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading data: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double getTotalPL() {
    try {
      double sum = 0;

      for (var t in trades) {
        try {
          final raw = t["realised_pl"];
          if (raw is num) {
            sum += raw.toDouble();
          } else if (raw != null) {
            sum += double.tryParse(raw.toString()) ?? 0;
          }
        } catch (_) {
          // Skip invalid trade entries
          continue;
        }
      }

      return sum;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F5FF),

      body: Column(
        children: [
          // -------------------------- HEADER --------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1A57E8), Color(0xff2465F3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ABBOT Wealth Management Ltd.",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Invoice",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------ CONTENT ------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  // 🔍 SEARCHABLE CUSTOMER FIELD - Styled like list_user.dart
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      final query = textEditingValue.text.toLowerCase();
                      return allCustomers.where((c) {
                        final name = (c["name"]?.toString() ?? "").toLowerCase();
                        final id = (c["id"]?.toString() ?? "").toLowerCase();
                        return name.contains(query) || id.contains(query);
                      });
                    },
                    displayStringForOption: (option) {
                      return "${option["id"]} - ${option["name"]}";
                    },
                    fieldViewBuilder: (
                      context,
                      controller,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      // Sync with searchController
                      if (controller.text != searchController.text) {
                        searchController.text = controller.text;
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: "Search by Customer ID or Name",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          searchController.text = value;
                        },
                        onSubmitted: (_) {
                          final text = controller.text.trim();
                          if (text.isNotEmpty) {
                            // Try to find customer by ID or name
                            final found = allCustomers.firstWhere(
                              (c) {
                                final id = c["id"]?.toString() ?? "";
                                final name = (c["name"]?.toString() ?? "").toLowerCase();
                                return id == text || name == text.toLowerCase();
                              },
                              orElse: () => <String, dynamic>{},
                            );
                            if (found.isNotEmpty) {
                              customerIdController.text = found["id"].toString();
                              loadInvoiceData();
                            }
                          }
                        },
                      );
                    },
                    onSelected: (option) {
                      customerIdController.text = option["id"].toString();
                      searchController.text = "${option["id"]} - ${option["name"]}";
                      loadInvoiceData();
                    },
                  ),

                  const SizedBox(height: 15),

                  // 🔄 LOADER
                  if (loading) const CircularProgressIndicator(),

                  const SizedBox(height: 10),

                  // 🔥 CONTENT CARDS
                  if (customer != null) buildCustomerCard(),
                  if (customer != null) const SizedBox(height: 20),

                  if (trades.isNotEmpty) buildTradesTable(),
                  if (trades.isNotEmpty) const SizedBox(height: 20),

                  if (trades.isNotEmpty) buildTotalCard(),
                  if (trades.isNotEmpty) const SizedBox(height: 20),

                  if (trades.isNotEmpty && customer != null)
                    buildGeneratePdfButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- CUSTOMER DETAILS CARD ----------------------
  Widget buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Customer Details",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1A57E8),
            ),
          ),
          const SizedBox(height: 8),
          buildRow("Customer ID", customer!['id']),
          buildRow("Name", customer!['name']),
          buildRow("Phone", customer!['phone']),
          buildRow("Address", customer!['address']),
        ],
      ),
    );
  }

  Widget buildRow(String title, dynamic value) {
    final valueStr = value?.toString() ?? "";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        "$title: $valueStr",
        style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
      ),
    );
  }

  // -------------------- TRADES TABLE -------------------------
  Widget buildTradesTable() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xffE4ECFF)),
            headingTextStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Color(0xff1A57E8),
              fontSize: 15,
            ),
            dataTextStyle: GoogleFonts.poppins(fontSize: 14),

            // 🔹 Added row stripe effect
            dataRowColor: WidgetStateProperty.all(Colors.white),

            columnSpacing: 28,
            horizontalMargin: 18,

            columns: const [
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Share")),
              DataColumn(label: Text("Qty")),
              DataColumn(label: Text("Exit Price")),
              DataColumn(label: Text("P&L")),
            ],

            rows: trades.asMap().entries.map((entry) {
              try {
                final t = entry.value;

                final realised = t["realised_pl"];
                double val = 0.0;
                if (realised is num) {
                  val = realised.toDouble();
                } else if (realised != null) {
                  val = double.tryParse(realised.toString()) ?? 0.0;
                }

                return DataRow(
                  cells: [
                    DataCell(Text(_formatDate(t["exit_date"]))),
                    DataCell(Text(t["share_name"]?.toString() ?? "")),
                    DataCell(Text(t["qty"]?.toString() ?? "0")),
                    DataCell(Text("₹${t["exit_price"]?.toString() ?? "0.00"}")),
                    DataCell(
                      Text(
                        "₹${val.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: val >= 0 ? Colors.green : Colors.red,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                );
              } catch (e) {
                // Return empty row if data is invalid
                return DataRow(
                  cells: List.generate(5, (_) => const DataCell(Text(""))),
                );
              }
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return "";
    final s = raw.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  // -------------------- TOTAL P&L CARD -------------------------
  Widget buildTotalCard() {
    double total = getTotalPL();

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: total >= 0 ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "Total P&L (Last 7 Days): ₹${total.toStringAsFixed(2)}",
        style: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: total >= 0 ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  // -------------------- GENERATE PDF BUTTON -------------------------
  Widget buildGeneratePdfButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _generateAndSharePdf(),
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: Text(
          "Generate PDF & Share",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff1A57E8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // -------------------- GENERATE PDF AND SHARE -------------------------
  Future<void> _generateAndSharePdf() async {
    if (customer == null || trades.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No data to generate PDF")));
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate invoice number
      final invoiceNo = InvoicePdf.generateInvoiceNumber();

      // Get current date
      final date = DateFormat("dd/MM/yyyy").format(DateTime.now());

      // Validate customer data before generating PDF
      final customerId = customer!['id']?.toString() ?? "";
      final customerName = customer!['name']?.toString() ?? "";
      final customerPhone = customer!['phone']?.toString() ?? "";
      final customerAddress = customer!['address']?.toString() ?? "";

      if (customerId.isEmpty) {
        throw Exception("Customer ID is required");
      }

      // Generate PDF (invoice number is auto-generated if not provided)
      final pdfBytes = await InvoicePdf.generate(
        invoiceNo: invoiceNo, // Optional - will auto-generate if null
        date: date,
        idCode: customerId,
        name: customerName,
        phone: customerPhone,
        address: customerAddress,
        trades: trades,
        totalPL: getTotalPL(),
      );

      // Save PDF to file
      Directory? directory;
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

      final customerIdForFile = customer!['id']?.toString() ?? "unknown";
      // Sanitize filename to avoid invalid characters
      final sanitizedId = customerIdForFile.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      );
      final fileName =
          "invoice_${sanitizedId}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final filePath = "${directory.path}/$fileName";
      final file = File(filePath);

      try {
        // Ensure directory exists
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        await file.writeAsBytes(pdfBytes);
      } catch (e) {
        throw Exception("Failed to write PDF file: $e");
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Verify file exists before sharing
      if (!await file.exists()) {
        throw Exception("PDF file was not created successfully");
      }

      // Share PDF
      if (context.mounted) {
        try {
          await Share.shareXFiles(
            [XFile(filePath)],
            text: "Invoice from ABBOTT WEALTH MANAGEMENT LIMITED",
            subject: "Invoice $invoiceNo",
          );
        } catch (shareError) {
          // If sharing fails, still show success message since PDF was created
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "PDF generated successfully but sharing failed: $shareError",
                ),
                backgroundColor: Colors.orange,
              ),
            );
            
            // Keep search bar data after successful PDF generation (even if sharing failed)
            // The search bar will continue to show the selected customer
          }
          return; // Exit early to avoid duplicate success message
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF generated and ready to share!"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Keep search bar data after successful PDF generation (don't clear)
        // The search bar will continue to show the selected customer
      }
    } catch (e) {
      // Close loading dialog if still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error generating PDF: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
