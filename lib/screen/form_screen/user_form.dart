import 'package:abbot/database/user_bd.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddUserScreen extends StatefulWidget {
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController customerIdController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isSaving = false;

  final RegExp nameRegex = RegExp(r"^[a-zA-Z ]+$");
  final RegExp phoneRegex = RegExp(r"^[0-9]+$");

  // Track if we're in edit mode
  Map<String, dynamic>? editingCustomer;
  bool get isEditMode => editingCustomer != null;

  @override
  void initState() {
    super.initState();
    // Check if we're editing (passed via route arguments)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        editingCustomer = args;
        _loadCustomerData();
      }
    });
  }

  void _loadCustomerData() {
    if (editingCustomer != null) {
      customerIdController.text = editingCustomer!["id"]?.toString() ?? "";
      nameController.text = editingCustomer!["name"]?.toString() ?? "";
      phoneController.text = editingCustomer!["phone"]?.toString() ?? "";
      addressController.text = editingCustomer!["address"]?.toString() ?? "";
    }
  }

  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final id = customerIdController.text.trim();

    // Check if ID exists (only for new customers, not when editing)
    if (!isEditMode) {
      final idExists = await DatabaseHelper.instance.checkCustomerIdExists(id);

      if (idExists) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Customer ID already exists!"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final data = {
      "id": id,
      "name": nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "address": addressController.text.trim(),
    };

    try {
      if (isEditMode) {
        // Update existing customer
        await DatabaseHelper.instance.updateCustomer(id, data);
      } else {
        // Insert new customer
        await DatabaseHelper.instance.insertCustomer(data);
      }

      setState(() => isSaving = false);

      // Clear form after successful save
      _clearForm();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode 
              ? "Customer updated successfully!" 
              : "Customer added successfully!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to customer list if editing (pushed from list)
      // For new customers in bottom nav, just clear form and stay on page
      if (isEditMode) {
        Navigator.pop(context, true);
      }
      // If not in edit mode, form is already cleared, user can add another
    } catch (e) {
      setState(() => isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearForm() {
    nameController.clear();
    customerIdController.clear();
    phoneController.clear();
    addressController.clear();
    editingCustomer = null;
  }

  // SAME TEXTFIELD STYLE AS TRADE EXIT FORM
  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xffEEF4FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff2465F3), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F5FF),

      body: Column(
        children: [
          // SAME GRADIENT HEADER
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
                SizedBox(height: 4),
                Text(
                  isEditMode ? "Edit Customer" : "Add Customer",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // FORM CARD (Same Style)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CUSTOMER NAME
                      TextFormField(
                        controller: nameController,
                        decoration: inputStyle("Customer Name"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Customer name is required";
                          }
                          if (!nameRegex.hasMatch(value.trim())) {
                            return "Only letters allowed";
                          }
                          if (value.trim().length < 3) {
                            return "Minimum 3 characters required";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // CUSTOMER ID (non-editable in edit mode)
                      TextFormField(
                        controller: customerIdController,
                        enabled: !isEditMode, // Disable in edit mode
                        decoration: inputStyle("Customer ID"),
                        onChanged: (v) {
                          if (!isEditMode) {
                            customerIdController.value = customerIdController
                                .value
                                .copyWith(
                                  text: v.toUpperCase().replaceAll(" ", ""),
                                  selection: TextSelection.collapsed(
                                    offset: v.length,
                                  ),
                                );
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Customer ID is required";
                          }
                          if (value.contains(" ")) {
                            return "Spaces not allowed";
                          }
                          if (value.length < 2) {
                            return "Minimum 2 characters required";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // PHONE NUMBER
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: inputStyle("Phone Number"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Phone number is required";
                          }
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return "Digits only";
                          }
                          if (value.length != 10) {
                            return "Phone number must be 10 digits";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // ADDRESS (Required)
                      TextFormField(
                        controller: addressController,
                        decoration: inputStyle("Address"),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Address is required";
                          }
                          if (value.trim().length < 5) {
                            return "Please enter a valid address (minimum 5 characters)";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : saveUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff1F5DEB),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            isSaving 
                                ? (isEditMode ? "Updating..." : "Saving...") 
                                : (isEditMode ? "Update Customer" : "Save Customer"),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
