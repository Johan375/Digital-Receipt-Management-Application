// lib/edit_receipt_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:financetrack/services/firestore_service.dart';
import 'package:financetrack/models/receipt.dart';

class EditReceiptPage extends StatefulWidget {
  final Receipt receipt;

  const EditReceiptPage({super.key, required this.receipt});

  @override
  State<EditReceiptPage> createState() => _EditReceiptPageState();
}

class _EditReceiptPageState extends State<EditReceiptPage> {
  // --- THEME COLORS ---
  final primaryColor = const Color(0xFF2E3192);
  final secondaryColor = const Color(0xFF00C6FF);
  final backgroundColor = const Color(0xFFF8F9FA);

  bool _isProcessing = false;

  // Removed _companyController
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  // Replaced Category with Payment Method
  String _selectedPaymentMethod = 'Cash';

  // Hardcoded list (Matches save_receipt_page.dart)
  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'E-Wallet',
    'QR Pay',
    'Online Transfer',
  ];

  @override
  void initState() {
    super.initState();
    // 1. Initialize text controllers with existing data
    // _companyController was removed
    _totalController.text = widget.receipt.total;

    // 2. Initialize Date
    try {
      _selectedDate = DateTime.parse(widget.receipt.transactionDate);
    } catch (e) {
      _selectedDate = DateTime.now();
    }
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // 3. Initialize Payment Method (Fallbacks to Cash if missing/invalid)
    if (_paymentMethods.contains(widget.receipt.paymentMethod)) {
      _selectedPaymentMethod = widget.receipt.paymentMethod;
    } else {
      _selectedPaymentMethod = 'Cash';
    }
  }

  @override
  void dispose() {
    _totalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- LOGIC: DATE PICKER ---
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // --- LOGIC: UPDATE RECEIPT ---
  Future<void> _updateReceipt() async {
    final double? totalAmount = double.tryParse(_totalController.text.trim());

    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Amount.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Create updated Receipt object
      // Note: ID is preserved from widget.receipt.id
      final updatedReceipt = Receipt(
        id: widget.receipt.id,
        // company/category removed
        total: totalAmount.toStringAsFixed(2),
        paymentMethod: _selectedPaymentMethod, // NEW FIELD
        createdAt: widget.receipt.createdAt, // Keep original creation time
        transactionDate: _selectedDate.toIso8601String(),
        localPath: widget.receipt.localPath, // Keep image path
      );

      await FirestoreService().updateReceipt(updatedReceipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt updated successfully!')),
        );
        Navigator.pop(context); // Return to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating receipt: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // --- LOGIC: DELETE RECEIPT ---
  Future<void> _deleteReceipt() async {
    // Confirm Dialog
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Receipt"),
          content: const Text("Are you sure? This cannot be undone."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red))
            ),
          ],
        )
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      // 1. Delete from Firestore
      await FirestoreService().deleteReceipt(widget.receipt);

      // 2. (Optional) Delete local image file to save space
      if (widget.receipt.localPath != null) {
        final file = File(widget.receipt.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (mounted) {
        Navigator.pop(context); // Go back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting: $e")),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Edit Receipt", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isProcessing ? null : _deleteReceipt,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. IMAGE PREVIEW (Optional)
            if (widget.receipt.localPath != null)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: FileImage(File(widget.receipt.localPath!)),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
              ),

            // 2. FORM FIELDS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Total Amount
                  _buildLabel("Total Amount"),
                  _buildTextField(
                    controller: _totalController,
                    icon: Icons.attach_money,
                    hint: "0.00",
                    isNumber: true,
                    color: Colors.green,
                    isBold: true,
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  _buildLabel("Date"),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _dateController,
                        icon: Icons.calendar_today,
                        hint: "Select Date",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Payment Method Dropdown (Replaces Category)
                  _buildLabel("Payment Method"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!)
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPaymentMethod,
                        icon: const Icon(Icons.payment, color: Colors.grey),
                        items: _paymentMethods.map((String method) {
                          return DropdownMenuItem<String>(value: method, child: Text(method));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPaymentMethod = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. UPDATE BUTTON
            Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                  ]
              ),
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _updateReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    else
                      const Icon(Icons.save, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      _isProcessing ? "Saving..." : "Save Changes",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(text, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isNumber = false,
    bool isBold = false,
    Color? color,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color ?? Colors.black87,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: color ?? Colors.grey[600], size: 20),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor),
        ),
      ),
    );
  }
}