// lib/save_receipt_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:financetrack/services/firestore_service.dart';
import 'package:financetrack/models/receipt.dart';

class SaveReceiptPage extends StatefulWidget {
  final File pickedImage;
  final String extractedText;

  const SaveReceiptPage({
    super.key,
    required this.pickedImage,
    required this.extractedText,
  });

  @override
  State<SaveReceiptPage> createState() => _SaveReceiptPageState();
}

class _SaveReceiptPageState extends State<SaveReceiptPage> {
  bool _isProcessing = false;

  // --- THEME COLORS ---
  final primaryColor = const Color(0xFF2E3192);
  final secondaryColor = const Color(0xFF00C6FF);
  final backgroundColor = const Color(0xFFF8F9FA);

  // --- CONTROLLERS ---
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // --- STATE VARIABLES ---
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();

  // Hardcoded list of payment methods
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
    // Initialize date with Today as default
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    // Run local OCR parsing immediately
    _parseLocalOcr(widget.extractedText);
  }

  @override
  void dispose() {
    _totalController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // --- Local OCR Logic (Amount & Date Only) ---
  void _parseLocalOcr(String text) {
    if (text.isEmpty) return;

    // 1. Total Extraction (Find largest number)
    double maxAmountFound = 0.0;

    // Regex matches prices like 10.50, 1,200.00
    final RegExp priceRegex = RegExp(r'\d+[\.,]\d{2}');
    final Iterable<RegExpMatch> allNumbers = priceRegex.allMatches(text);

    for (var match in allNumbers) {
      String foundNumber = match.group(0)?.replaceAll(',', '.') ?? '0.00';
      double? parsedValue = double.tryParse(foundNumber);

      // Logic: The "Total" is usually the largest number on the receipt
      if (parsedValue != null && parsedValue > maxAmountFound) {
        maxAmountFound = parsedValue;
      }
    }

    // 2. Date Extraction (Simple Regex Fallback)
    DateTime? foundDate;
    final RegExp dateRegex = RegExp(r'(\d{1,2}[-./]\d{1,2}[-./]\d{2,4})');
    final dateMatch = dateRegex.firstMatch(text);

    if (dateMatch != null) {
      try {
        String rawDate = dateMatch.group(1)!;
        // Normalize separators to /
        rawDate = rawDate.replaceAll('.', '/').replaceAll('-', '/');
        List<String> parts = rawDate.split('/');

        if (parts.length == 3) {
          int p1 = int.parse(parts[0]);
          int p2 = int.parse(parts[1]);
          int p3 = int.parse(parts[2]);

          // Heuristic: if p1 > 1000, it's YYYY/MM/DD, else DD/MM/YYYY
          if (p1 > 1000) {
            foundDate = DateTime(p1, p2, p3);
          } else {
            // Fix 2-digit year (e.g. 23 -> 2023)
            if (p3 < 100) p3 += 2000;
            foundDate = DateTime(p3, p2, p1);
          }
        }
      } catch (e) {
        debugPrint("Local Date Parse Error: $e");
      }
    }

    // 3. Update UI
    if (mounted) {
      setState(() {
        if (maxAmountFound > 0.0) {
          _totalController.text = maxAmountFound.toStringAsFixed(2);
        }
        if (foundDate != null) {
          _selectedDate = foundDate!;
          _dateController.text = DateFormat('yyyy-MM-dd').format(foundDate!);
        }
      });
    }
  }

  // --- Date Picker Logic ---
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

  // --- Image Preview Logic ---
  void _showFullImage() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(
                widget.pickedImage,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SAVE LOGIC (With Budget Check) ---
  Future<void> saveReceipt() async {
    if (_isProcessing) return;

    final double? totalAmount = double.tryParse(_totalController.text.trim());

    // Validation
    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Amount.')),
      );
      return;
    }

    setState(() { _isProcessing = true; });

    try {
      // 1. Budget Check Logic
      final currentTotal = await FirestoreService().getTotalSpent();
      final budgetLimit = await FirestoreService().getMonthlyBudget();

      // Check if limit is set (>0) and if adding this receipt exceeds it
      if (budgetLimit > 0 && (currentTotal + totalAmount) > budgetLimit) {

        // Show Warning Dialog
        if (mounted) {
          final bool? proceed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 10),
                  Text("Budget Alert")
                ],
              ),
              content: Text(
                "Saving this receipt will exceed your monthly budget of RM ${budgetLimit.toStringAsFixed(0)}.\n\n"
                    "Current Spent: RM ${currentTotal.toStringAsFixed(2)}\n"
                    "New Total: RM ${(currentTotal + totalAmount).toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false), // Cancel
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true), // Proceed
                  child: const Text("Proceed Anyway", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );

          // If user clicked Cancel (or dismissed dialog), stop saving
          if (proceed != true) {
            setState(() { _isProcessing = false; });
            return;
          }
        }
      }

      // 2. Create Receipt Object (FinanceTrack Model)
      final newReceipt = Receipt(
        total: totalAmount.toStringAsFixed(2),
        paymentMethod: _selectedPaymentMethod,
        createdAt: DateTime.now().toIso8601String(),
        transactionDate: _selectedDate.toIso8601String(),
        localPath: widget.pickedImage.path,
      );

      // 3. Save to Firestore
      await FirestoreService().addReceipt(newReceipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved successfully!')),
        );
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _isProcessing = false; });
    }
  }

  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text('Review Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_isProcessing)
            LinearProgressIndicator(
              backgroundColor: primaryColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. IMAGE PREVIEW CARD
                  GestureDetector(
                    onTap: _showFullImage,
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              widget.pickedImage,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    "Tap to view full receipt",
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. FORM CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Receipt Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                        const SizedBox(height: 20),

                        // Total Amount
                        _buildLabel("Total Amount"),
                        _buildTextField(
                          controller: _totalController,
                          icon: Icons.attach_money,
                          hint: "0.00",
                          isNumber: true,
                          isBold: true,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 15),

                        // Transaction Date
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
                        const SizedBox(height: 15),

                        // Payment Method Dropdown
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
                              style: const TextStyle(fontSize: 16, color: Colors.black87),
                              items: _paymentMethods.map((String method) {
                                return DropdownMenuItem<String>(
                                    value: method,
                                    child: Text(method)
                                );
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

                  // 3. SAVE BUTTON
                  Container(
                    height: 55,
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
                      onPressed: _isProcessing ? null : saveReceipt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isProcessing)
                            const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          else
                            const Icon(Icons.check, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            _isProcessing ? "Saving..." : "Save Receipt",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(text, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 13)),
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