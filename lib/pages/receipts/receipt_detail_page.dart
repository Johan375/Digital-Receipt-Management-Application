// lib/receipt_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:financetrack/models/receipt.dart';
import 'edit_receipt_page.dart';

class ReceiptDetailPage extends StatefulWidget {
  final Receipt receipt;
  const ReceiptDetailPage({super.key, required this.receipt});

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  // --- THEME COLORS ---
  final primaryColor = const Color(0xFF2E3192);
  final secondaryColor = const Color(0xFF00C6FF);
  final backgroundColor = const Color(0xFFF8F9FA);

  // We need state to handle updates if the user edits the receipt
  late Receipt _currentReceipt;

  @override
  void initState() {
    super.initState();
    _currentReceipt = widget.receipt;
  }

  // --- ACTIONS ---

  // 1. Show Full Screen Image (Zoomable)
  void _showFullImage(BuildContext context, String imagePath) {
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
              child: Image.file(File(imagePath), fit: BoxFit.contain),
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

  // 2. Navigate to Edit Page
  Future<void> _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditReceiptPage(receipt: _currentReceipt)),
    );
    // In a real app with Firestore streams, the data updates automatically.
    // However, if we passed data via constructor, we might want to pop or refresh.
    // Since we are using StreamBuilder in the previous list page,
    // simply going back will show updated data.
    // But if we want to update THIS page immediately without a stream:
    // (We would need to re-fetch the doc, but for now we rely on the List Page to refresh).
    if (mounted) {
      Navigator.pop(context); // Go back to list to see changes
    }
  }

  @override
  Widget build(BuildContext context) {
    // Formatters
    final currencyFormat = NumberFormat("#,##0.00", "en_US");

    DateTime dateObj;
    try {
      dateObj = DateTime.parse(_currentReceipt.transactionDate);
    } catch (e) {
      dateObj = DateTime.now();
    }

    final day = DateFormat('d').format(dateObj);
    final month = DateFormat('MMM').format(dateObj);
    final year = DateFormat('y').format(dateObj);

    // Parse creation time for "Added on..."
    DateTime createdObj;
    try {
      createdObj = DateTime.parse(_currentReceipt.createdAt);
    } catch (e) {
      createdObj = DateTime.now();
    }
    final time = DateFormat('h:mm a').format(createdObj);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Receipt Details", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
            onPressed: _navigateToEdit,
            tooltip: "Edit Receipt",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. IMAGE PREVIEW CARD
            if (_currentReceipt.localPath != null)
              GestureDetector(
                onTap: () => _showFullImage(context, _currentReceipt.localPath!),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_currentReceipt.localPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 50)
                          ),
                        ),
                      ),
                      // "Tap to view" overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Tap to view full receipt",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 25),

            // 2. DETAILS CARD
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Amount
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Total Amount",
                          style: TextStyle(color: Colors.grey[500], fontSize: 14, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "RM ${currencyFormat.format(_currentReceipt.amount)}",
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: primaryColor
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  // REPLACED: Category -> Payment Method
                  _buildDetailRow(Icons.payment, "Payment Method", _currentReceipt.paymentMethod),
                  const SizedBox(height: 15),

                  // REPLACED: Company -> Just Date (Or removed entirely since Company is gone)
                  _buildDetailRow(Icons.calendar_month, "Date", "$day $month $year"),
                  const SizedBox(height: 15),

                  _buildDetailRow(Icons.access_time, "Time Added", time),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Delete Button (Alternative location)
            TextButton.icon(
              onPressed: _navigateToEdit,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text("Remove Receipt", style: TextStyle(color: Colors.red)),
            )
          ],
        ),
      ),
    );
  }

  // Helper for rows
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FF), // Very light blue
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}