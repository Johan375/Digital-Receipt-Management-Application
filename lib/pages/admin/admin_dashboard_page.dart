// lib/pages/admin/admin_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Admin Components
import 'manage_users_page.dart';
// Note: manage_categories_page.dart is removed

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // --- THEME COLORS ---
  final primaryColor = const Color(0xFF2E3192);
  final secondaryColor = const Color(0xFF00C6FF);
  final backgroundColor = const Color(0xFFF8F9FA);

  bool _isSyncing = false;

  // --- ANALYTICS STATE ---
  int _totalUsers = 0;
  int _totalReceipts = 0;
  double _totalTransactionValue = 0.0;

  // Replaced _categoryData with _paymentMethodData
  Map<String, double> _paymentMethodData = {};

  @override
  void initState() {
    super.initState();
    _loadCachedMetrics();
  }

  // 1. Load data from a 'metrics/global' document (Fast load)
  Future<void> _loadCachedMetrics() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('metrics').doc('global').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _totalUsers = data['totalUsers'] ?? 0;
            _totalReceipts = data['totalReceipts'] ?? 0;
            _totalTransactionValue = (data['totalTransactionValue'] ?? 0).toDouble();

            // Load Payment Method breakdown
            final Map<String, dynamic> methods = data['paymentMethodData'] ?? {};
            _paymentMethodData = methods.map((key, value) => MapEntry(key, (value as num).toDouble()));
          });
        }
      } else {
        // If no cache exists, run a sync automatically
        _runDataSync();
      }
    } catch (e) {
      debugPrint("Error loading cached metrics: $e");
    }
  }

  // 2. Heavy Task: Scan database to calculate new totals (The "Sync" button)
  Future<void> _runDataSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      int usersCount = 0;
      int receiptsCount = 0;
      double totalValue = 0.0;
      Map<String, double> tempMethodTotals = {};

      // A. Get All Users
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      usersCount = usersSnapshot.docs.length;

      // B. Loop through Users to get Receipts (Aggregating Global Data)
      // Note: In a massive production app, you would use Cloud Functions for this.
      // For FinanceTrack, client-side aggregation works fine for < 1000 users.
      for (var userDoc in usersSnapshot.docs) {
        final receiptsSnapshot = await userDoc.reference.collection('receipts').get();
        receiptsCount += receiptsSnapshot.docs.length;

        for (var receiptDoc in receiptsSnapshot.docs) {
          final data = receiptDoc.data();

          // Sum Total
          final amountString = data['total'] as String? ?? '0';
          final amount = double.tryParse(amountString) ?? 0.0;
          totalValue += amount;

          // Group by Payment Method
          final method = data['paymentMethod'] as String? ?? 'Cash';
          tempMethodTotals.update(method, (val) => val + amount, ifAbsent: () => amount);
        }
      }

      // C. Save to Firestore 'metrics/global' for caching
      await FirebaseFirestore.instance.collection('metrics').doc('global').set({
        'totalUsers': usersCount,
        'totalReceipts': receiptsCount,
        'totalTransactionValue': totalValue,
        'paymentMethodData': tempMethodTotals,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // D. Update UI
      if (mounted) {
        setState(() {
          _totalUsers = usersCount;
          _totalReceipts = receiptsCount;
          _totalTransactionValue = totalValue;
          _paymentMethodData = tempMethodTotals;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analytics synced successfully!')),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // --- UI WIDGETS ---

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 15),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort chart data
    final sortedChartData = _paymentMethodData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Admin Dashboard", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATS ROW
            Row(
              children: [
                _buildSummaryCard(
                    "Total Users",
                    _totalUsers.toString(),
                    Icons.people,
                    Colors.blue
                ),
                const SizedBox(width: 15),
                _buildSummaryCard(
                    "Total Processed",
                    "RM ${NumberFormat.compact().format(_totalTransactionValue)}",
                    Icons.payments,
                    Colors.green
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 2. PAYMENT METHODS CHART (Replaces Categories)
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
                  const Text("Global Payment Trends", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  if (_paymentMethodData.isEmpty)
                    const Center(child: Text("No data synced yet.", style: TextStyle(color: Colors.grey)))
                  else
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections: sortedChartData.map((entry) {
                            final index = sortedChartData.indexOf(entry);
                            final color = Colors.primaries[index % Colors.primaries.length];
                            return PieChartSectionData(
                              color: color,
                              value: entry.value,
                              title: '${(entry.value / _totalTransactionValue * 100).toStringAsFixed(0)}%',
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Legend
                  Wrap(
                    spacing: 10,
                    runSpacing: 5,
                    children: sortedChartData.map((entry) {
                      final index = sortedChartData.indexOf(entry);
                      final color = Colors.primaries[index % Colors.primaries.length];
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, color: color),
                          const SizedBox(width: 5),
                          Text("${entry.key} (${NumberFormat.compact().format(entry.value)})", style: const TextStyle(fontSize: 11)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. ADMIN ACTIONS
            const Text("Management Tools", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                children: [
                  // --- REMOVED: Manage Categories ---

                  // Manage Users
                  _buildActionItem(
                    'Manage Users',
                    'Ban or unban suspicious accounts',
                    Icons.people_alt_outlined,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageUsersPage())),
                  ),

                  Divider(height: 1, color: Colors.grey[200], indent: 60, endIndent: 20),

                  // Sync Analytics
                  _buildActionItem(
                    'Sync Analytics',
                    'Recalculate global totals manually',
                    Icons.cloud_sync_outlined,
                    _runDataSync,
                  ),
                ],
              ),
            ),

            // Loading Indicator for Sync
            if (_isSyncing)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      const SizedBox(height: 10),
                      Text("Aggregating global data...", style: TextStyle(color: Colors.grey[600], fontSize: 12))
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}