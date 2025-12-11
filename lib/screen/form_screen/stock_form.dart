import 'package:abbot/database/stock_bd.dart';
import 'package:abbot/database/user_bd.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:abbot/pdf/daliy_pdf_genrator.dart';
import 'package:share_plus/share_plus.dart';

class TradeExitForm extends StatefulWidget {
  const TradeExitForm({super.key});

  @override
  State<TradeExitForm> createState() => _TradeExitFormState();
}

class _TradeExitFormState extends State<TradeExitForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController shareName = TextEditingController();
  final TextEditingController exitDate = TextEditingController();
  final TextEditingController customerId = TextEditingController();
  final TextEditingController executedPrice = TextEditingController();
  final TextEditingController qty = TextEditingController();
  final TextEditingController avgBuyPrice = TextEditingController();
  final TextEditingController exitPrice = TextEditingController();
  final TextEditingController brokerage = TextEditingController();

  String productType = "BUY";
  double realisedPL = 0;

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  String? selectedCustomerId;
  String sortOption = "name_asc"; // name_asc, name_desc, id_asc, id_desc
  final TextEditingController customerSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    exitDate.text = DateFormat("dd/MM/yyyy").format(DateTime.now());
    loadCustomers();
    customerSearchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    shareName.dispose();
    exitDate.dispose();
    customerId.dispose();
    executedPrice.dispose();
    qty.dispose();
    avgBuyPrice.dispose();
    exitPrice.dispose();
    brokerage.dispose();
    customerSearchController.dispose();
    super.dispose();
  }

  Future<void> loadCustomers() async {
    customers = await DatabaseHelper.instance.getAllCustomers();
    _applySorting();
    _filterCustomers();
  }

  void _applySorting() {
    switch (sortOption) {
      case "name_asc":
        customers.sort((a, b) => (a["name"]?.toString() ?? "").compareTo(b["name"]?.toString() ?? ""));
        break;
      case "name_desc":
        customers.sort((a, b) => (b["name"]?.toString() ?? "").compareTo(a["name"]?.toString() ?? ""));
        break;
      case "id_asc":
        customers.sort((a, b) => (a["id"]?.toString() ?? "").compareTo(b["id"]?.toString() ?? ""));
        break;
      case "id_desc":
        customers.sort((a, b) => (b["id"]?.toString() ?? "").compareTo(a["id"]?.toString() ?? ""));
        break;
    }
  }

  void _filterCustomers() {
    final query = customerSearchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      filteredCustomers = List.from(customers);
    } else {
      filteredCustomers = customers.where((c) {
        final name = (c["name"]?.toString() ?? "").toLowerCase();
        final id = (c["id"]?.toString() ?? "").toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    }
    setState(() {});
  }

  void _resetForm() {
    shareName.clear();
    exitDate.text = DateFormat("dd/MM/yyyy").format(DateTime.now());
    customerId.clear();
    customerSearchController.clear();
    executedPrice.clear();
    qty.clear();
    avgBuyPrice.clear();
    exitPrice.clear();
    brokerage.clear();

    setState(() {
      productType = "BUY";
      realisedPL = 0;
      selectedCustomerId = null;
    });
  }

  void _calculatePL() {
    try {
      // Validate required fields
      if (avgBuyPrice.text.trim().isEmpty ||
          exitPrice.text.trim().isEmpty ||
          qty.text.trim().isEmpty ||
          brokerage.text.trim().isEmpty) {
        setState(() {
          realisedPL = 0;
        });
        return;
      }

      // Parse and validate numeric values
      final avg = double.tryParse(avgBuyPrice.text.replaceAll(',', '').trim()) ?? 0;
      final exitP = double.tryParse(exitPrice.text.replaceAll(',', '').trim()) ?? 0;
      final q = double.tryParse(qty.text.replaceAll(',', '').trim()) ?? 0;
      final totalBrokerage = double.tryParse(brokerage.text.replaceAll(',', '').trim()) ?? 0;

      // Validate values are positive and not zero for required fields
      if (avg <= 0 || exitP <= 0 || q <= 0) {
        setState(() {
          realisedPL = 0;
        });
        return;
      }

      if (totalBrokerage < 0) {
        setState(() {
          realisedPL = 0;
        });
        return;
      }

      // Calculate P&L using manual brokerage
      double calculatedPL;
      if (productType == "BUY") {
        // For BUY: Profit = (Exit Price - Avg Buy Price) × Quantity - Brokerage
        calculatedPL = (exitP - avg) * q - totalBrokerage;
      } else {
        // For SELL: Profit = (Avg Buy Price - Exit Price) × Quantity - Brokerage
        calculatedPL = (avg - exitP) * q - totalBrokerage;
      }

      // Validate P&L calculation
      if (calculatedPL.isNaN || calculatedPL.isInfinite) {
        calculatedPL = 0;
      }

      setState(() {
        realisedPL = calculatedPL;
      });
    } catch (e) {
      // Handle any calculation errors
      setState(() {
        realisedPL = 0;
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      exitDate.text = DateFormat("dd/MM/yyyy").format(picked);
    }
  }

  // -----------------------------------------
  // BEAUTIFUL TEXTFIELD
  // -----------------------------------------
  Widget appTextField(
    String label,
    TextEditingController controller, {
    bool number = false,
    bool required = true,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return TextFormField(
      controller: controller,
      keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xffEEF4FF),
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xff2465F5), width: 2),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return "Required";
        }
        if (number && value != null && value.isNotEmpty) {
          final num = double.tryParse(value);
          if (num == null) {
            return "Invalid number";
          }
          if (num < 0) {
            return "Must be positive";
          }
        }
        return null;
      },
      onChanged: (_) => _calculatePL(),
    );
  }

  // -----------------------------------------
  // PRODUCT TYPE DROPDOWN
  // -----------------------------------------
  Widget appDropdown() {
    return DropdownButtonFormField(
      value: productType,
      items: const [
        DropdownMenuItem(value: "BUY", child: Text("BUY")),
        DropdownMenuItem(value: "SELL", child: Text("SELL")),
      ],
      decoration: InputDecoration(
        labelText: "Product Type",
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        filled: true,
        fillColor: const Color(0xffEEF4FF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: (v) {
        setState(() => productType = v.toString());
        _calculatePL();
      },
    );
  }

  // -----------------------------------------
  // UI START
  // -----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F5FF),

      // -------------------------- HEADER --------------------------
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: MediaQuery.of(context).size.width * 0.05,
              right: MediaQuery.of(context).size.width * 0.05,
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
                    fontSize: MediaQuery.of(context).size.width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Trade Exit Form",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------ SORT DROPDOWN (After Header) ------------------------
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.045,
              18,
              MediaQuery.of(context).size.width * 0.045,
              12,
            ),
            child: DropdownButtonFormField<String>(
              value: sortOption,
              decoration: InputDecoration(
                labelText: "Sort By",
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(value: "name_asc", child: Text("Name (A-Z)")),
                DropdownMenuItem(value: "name_desc", child: Text("Name (Z-A)")),
                DropdownMenuItem(value: "id_asc", child: Text("ID (Ascending)")),
                DropdownMenuItem(value: "id_desc", child: Text("ID (Descending)")),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sortOption = value;
                    _applySorting();
                    _filterCustomers();
                  });
                }
              },
            ),
          ),

          // ------------------------ SEARCH BAR (After Sort) ------------------------
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.045,
            ),
            child: Autocomplete<Map<String, dynamic>>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return filteredCustomers;
                }
                final query = textEditingValue.text.toLowerCase();
                return filteredCustomers.where((c) {
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
                // Sync with our search controller
                if (controller.text != customerSearchController.text) {
                  customerSearchController.text = controller.text;
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: "Search Customer ID or Name",
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
                    customerSearchController.text = value;
                    _filterCustomers();
                  },
                );
              },
              onSelected: (option) async {
                selectedCustomerId = option["id"].toString();
                customerId.text = selectedCustomerId!;
                customerSearchController.text = "${option["id"]} - ${option["name"]}";
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 18),

          // ------------------------ FORM CARD ------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.045),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.055),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Display selected customer info
                      if (selectedCustomerId != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xffEEF4FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xff2465F3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person, color: Color(0xff2465F3)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Selected: ${customerSearchController.text}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff2465F3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      appTextField("Share Name", shareName),
                      const SizedBox(height: 14),

                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: appTextField("Exit Date", exitDate),
                        ),
                      ),
                      const SizedBox(height: 14),

                      appTextField(
                        "Executed Price",
                        executedPrice,
                        number: true,
                      ),
                      const SizedBox(height: 14),

                      appDropdown(),
                      const SizedBox(height: 14),

                      appTextField("Quantity", qty, number: true),
                      const SizedBox(height: 14),

                      appTextField("Avg Buy Price", avgBuyPrice, number: true),
                      const SizedBox(height: 14),

                      appTextField("Exit Price", exitPrice, number: true),
                      const SizedBox(height: 14),

                      appTextField("Brokerage", brokerage, number: true),
                      const SizedBox(height: 20),

                      // ---------------- REALISED P&L BOX ----------------
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: realisedPL >= 0
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  realisedPL >= 0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  color: realisedPL >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 14),

                                // Full Text in One Line
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: realisedPL >= 0
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                      children: [
                                        const TextSpan(text: "RealisedP&L: "),
                                        TextSpan(
                                          text:
                                              "₹${realisedPL.toStringAsFixed(2)}",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ---------------- GENERATE PDF BUTTON ----------------
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1F5DEB),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            // Show loading indicator
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              // --- 1️⃣ VALIDATE CUSTOMER SELECTED ---
                              if (selectedCustomerId == null || customerId.text.trim().isEmpty) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select a customer from the search bar.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              // --- 2️⃣ VALIDATE NUMERIC FIELDS ---
                              try {
                                _calculatePL();
                                // Validate that calculations are valid
                                if (realisedPL.isNaN || realisedPL.isInfinite) {
                                  throw Exception("Invalid calculation result. Please check your input values.");
                                }
                              } catch (calcError) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Calculation error: $calcError"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              // --- 3️⃣ VALIDATE CUSTOMER EXISTS ---
                              Map<String, dynamic>? customerData;
                              try {
                                customerData = await DatabaseHelper.instance
                                    .getCustomerById(customerId.text.trim());
                              } catch (dbError) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Database error: $dbError"),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              if (customerData == null) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Customer ID does not exist! Please select a valid ID.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              final customerName = customerData["name"]?.toString() ?? "";
                              if (customerName.isEmpty) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Customer name is missing. Please select a valid customer."),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }

                              // --- 4️⃣ SAVE TRADE ---
                              try {
                                await TradeExitDB.instance.insert({
                                  "user_name": customerName,
                                  "share_name": shareName.text.trim(),
                                  "product_type": productType,
                                  "exit_date": exitDate.text.trim(),
                                  "customer_id": customerId.text.trim().toString(),
                                  "executed_price": executedPrice.text.trim(),
                                  "qty": qty.text.trim(),
                                  "avg_buy_price": avgBuyPrice.text.trim(),
                                  "exit_price": exitPrice.text.trim(),
                                  "brokerage": brokerage.text.trim(),
                                  "realised_pl": realisedPL,
                                });
                              } catch (saveError) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error saving trade: ${saveError.toString()}"),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                                return;
                              }

                              // --- 5️⃣ GENERATE PDF ---
                              String pdfPath;
                              try {
                                pdfPath = await PdfGenerated().generatePdf(
                                  userName: customerName,
                                  shareName: shareName.text.trim(),
                                  productType: productType,
                                  exitDate: exitDate.text.trim(),
                                  customerId: customerId.text.trim(),
                                  executedPrice: executedPrice.text.trim(),
                                  qty: qty.text.trim(),
                                  avgBuyPrice: avgBuyPrice.text.trim(),
                                  exitPrice: exitPrice.text.trim(),
                                  brokerage: brokerage.text.trim(),
                                  realisedPL: realisedPL,
                                );
                              } catch (pdfError) {
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error generating PDF: ${pdfError.toString()}"),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                                return;
                              }

                              // --- 6️⃣ SHARE PDF ---
                              try {
                                if (!mounted) return;
                                await Share.shareXFiles(
                                  [XFile(pdfPath)],
                                  text: "Trade Exit PDF",
                                );
                              } catch (shareError) {
                                // PDF was generated successfully, just sharing failed
                                if (mounted) {
                                  Navigator.of(context).pop(); // Close loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("PDF saved successfully but sharing failed: ${shareError.toString()}"),
                                      backgroundColor: Colors.orange,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                                return;
                              }

                              // --- 7️⃣ SUCCESS ---
                              if (mounted) {
                                Navigator.of(context).pop(); // Close loading
                                _resetForm();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Data Saved & PDF Generated Successfully"),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Catch any unexpected errors
                              if (mounted) {
                                Navigator.of(context).pop(); // Close loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Unexpected error: ${e.toString()}"),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              }
                            }
                          },

                          child: Text(
                            "Generate PDF",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
