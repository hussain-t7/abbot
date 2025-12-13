import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:abbot/database/user_bd.dart';
import 'package:abbot/screen/form_screen/user_form.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredList = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    customers = await DatabaseHelper.instance.getAllCustomers();
    filteredList = customers;
    setState(() {});
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      filteredList = customers;
    } else {
      filteredList = customers.where((c) {
        return c["name"].toLowerCase().contains(query.toLowerCase()) ||
            c["id"].toString().toLowerCase().contains(query.toLowerCase()) ||
            c["phone"].toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  Future<void> _editCustomer(Map<String, dynamic> customer) async {
    // Navigate to customer form with customer data
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUserScreen(),
        settings: RouteSettings(arguments: customer),
      ),
    );
    
    // Refresh list after returning from edit
    loadCustomers();
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Customer",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete customer '${customer["name"]}' (ID: ${customer["id"]})?",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseHelper.instance.deleteCustomer(customer["id"].toString());
        
        // Reload customers from database to ensure UI is in sync
        await loadCustomers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Customer deleted successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error deleting customer: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F5FF),

      body: Column(
        children: [
          // 🔵 GRADIENT HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              left: 20,
              right: 20,
              bottom: 28,
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
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Customer List",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 🔍 SEARCH BAR + REFRESH BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearch,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search by name, ID, phone...",
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  onPressed: () {
                    searchController.clear();
                    loadCustomers();
                  },
                  icon: const Icon(Icons.refresh),
                  color: Colors.blue,
                  iconSize: 30,
                ),
              ],
            ),
          ),

          // 📋 TABLE CONTAINER WITH SHADOW
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          "No Customers Found",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            const Color(0xffEEF4FF),
                          ),
                          headingTextStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff1A57E8),
                          ),
                          dataTextStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),

                          border: TableBorder.all(color: Colors.grey.shade300),

                          columns: [
                            const DataColumn(label: Text("Customer ID")),
                            const DataColumn(label: Text("Name")),
                            const DataColumn(label: Text("Phone")),
                            const DataColumn(label: Text("Address")),
                            const DataColumn(label: Text("Actions")),
                          ],

                          rows: filteredList.map((c) {
                            return DataRow(
                              cells: [
                                DataCell(Text(c["id"]?.toString() ?? "")),
                                DataCell(Text(c["name"]?.toString() ?? "")),
                                DataCell(Text(c["phone"]?.toString() ?? "")),
                                DataCell(Text(c["address"]?.toString() ?? "")),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Edit Button
                                      ElevatedButton.icon(
                                        onPressed: () => _editCustomer(c),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text("Edit"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Delete Button
                                      ElevatedButton.icon(
                                        onPressed: () => _deleteCustomer(c),
                                        icon: const Icon(Icons.delete, size: 16),
                                        label: const Text("Delete"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
