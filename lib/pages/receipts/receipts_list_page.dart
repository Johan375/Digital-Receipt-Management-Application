// lib/receipts_list_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Removed: csv, path_provider, share_plus, archive imports

import 'package:financetrack/services/firestore_service.dart';
import 'package:financetrack/models/receipt.dart';
import 'edit_receipt_page.dart';

class ReceiptsListPage extends StatefulWidget {
  const ReceiptsListPage({super.key});

  @override
  State<ReceiptsListPage> createState() => _ReceiptsListPageState();
}

class _ReceiptsListPageState extends State<ReceiptsListPage> {
  // Theme Colors
  final primaryColor = const Color(0xFF2E3192);
  final backgroundColor = const Color(0xFFF8F9FA);

  // State for Filters
  String? _selectedPaymentFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  // Removed: _isExporting state variable

  final List<String> _paymentMethods = [
    'Cash', 'Credit Card', 'Debit Card', 'E-Wallet', 'QR Pay', 'Online Transfer'
  ];

  // --- LOGIC: DATE PICKER ---
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // Removed: _exportReceipts() function
  // Removed: getTemporaryExportDirectory() function

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("My Receipts", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        // Removed: actions: [ ... Export Button ... ]
      ),
      body: Column(
        children: [
          // --- FILTER SECTION ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            color: backgroundColor,
            child: Column(
              children: [
                // 1. Payment Method Filter (Horizontal Scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // "All" Chip
                      _buildFilterChip(
                        label: 'All',
                        isSelected: _selectedPaymentFilter == null,
                        onTap: () => setState(() => _selectedPaymentFilter = null),
                      ),
                      // Dynamic Payment Method Chips
                      ..._paymentMethods.map((method) => _buildFilterChip(
                        label: method,
                        isSelected: _selectedPaymentFilter == method,
                        onTap: () => setState(() => _selectedPaymentFilter = method),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Date Range Filter Button
                GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              _startDate == null
                                  ? "Filter by Date Range"
                                  : "${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}",
                              style: TextStyle(
                                color: _startDate == null ? Colors.grey[600] : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (_startDate != null)
                          GestureDetector(
                            onTap: () => setState(() { _startDate = null; _endDate = null; }),
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          )
                        else
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- LIST SECTION ---
          Expanded(
            child: StreamBuilder<List<Receipt>>(
              // Pass Date Range to Service (Server-side filter)
              stream: FirestoreService().getReceiptsStream(startDate: _startDate, endDate: _endDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("No receipts found.", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                // Apply Payment Method Filter (Client-side filter)
                final receipts = snapshot.data!.where((r) {
                  if (_selectedPaymentFilter == null) return true;
                  return r.paymentMethod == _selectedPaymentFilter;
                }).toList();

                if (receipts.isEmpty) {
                  return Center(child: Text("No receipts match '$_selectedPaymentFilter'", style: TextStyle(color: Colors.grey[500])));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: receipts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    final formatter = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.payment, color: primaryColor),
                        ),
                        title: Text(
                          receipt.paymentMethod,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            DateFormat('dd MMM yyyy, h:mm a').format(receipt.date),
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ),
                        trailing: Text(
                          formatter.format(receipt.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16),
                        ),
                        onTap: () {
                          // Navigate to Edit/Detail Page
                          Navigator.push(
                            context, MaterialPageRoute(builder: (context) => EditReceiptPage(receipt: receipt)),
                          ).then((_) => setState((){})); // Refresh on back (if needed)
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER: FILTER CHIP ---
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey[300]!,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}