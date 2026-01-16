// lib/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:financetrack/services/firestore_service.dart';
import 'package:financetrack/models/receipt.dart';
import 'package:financetrack/pages/receipts/scan_page.dart';
import 'package:financetrack/pages/receipts/receipts_list_page.dart';
import 'reports_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final primaryColor = const Color(0xFF2E3192);

  // --- STATE: Selected Month ---
  DateTime _selectedMonth = DateTime.now();

  // Helper to change months
  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

  // --- Components ---
  BoxDecoration _sectionContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email?.split('@').first ?? 'User';

    // Display Format: "January 2024"
    final monthDisplay = DateFormat('MMMM yyyy').format(_selectedMonth);

    return FutureBuilder<List<double>>(
      // Re-fetch data whenever _selectedMonth changes
      future: Future.wait([
        FirestoreService().getSpecificMonthSpent(_selectedMonth), // <-- Uses selected date
        FirestoreService().getMonthlyBudget(),
        FirestoreService().getTotalSpent(),
      ]),
      builder: (context, snapshot) {
        final monthSpent = snapshot.data?[0] ?? 0.0;
        final budgetLimit = snapshot.data?[1] ?? 0.0;
        final lifetimeTotal = snapshot.data?[2] ?? 0.0;

        final formattedMonthSpent = NumberFormat('#,##0.00').format(monthSpent);
        final formattedLifetime = NumberFormat('#,##0.00').format(lifetimeTotal);

        double progress = 0.0;
        if (budgetLimit > 0) {
          progress = (monthSpent / budgetLimit).clamp(0.0, 1.0);
        }
        final isOverBudget = budgetLimit > 0 && monthSpent > budgetLimit;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $userName 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),

            // --- MAIN CARD ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E3192), Color(0xFF00C6FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E3192).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // --- MONTH SELECTOR ROW ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Arrow
                        InkWell(
                          onTap: () => _changeMonth(-1),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                          ),
                        ),

                        // Month Name
                        Text(
                          monthDisplay,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),

                        // Right Arrow (Only if not in future? Optional. We allow future for now)
                        InkWell(
                          onTap: () => _changeMonth(1),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- EXPENSE DISPLAY ---
                    const Text(
                      'Total Expenses',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'RM $formattedMonthSpent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- BUDGET BAR ---
                    if (budgetLimit > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOverBudget ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                isOverBudget ? "Over Budget" : "On Track",
                                style: TextStyle(
                                    color: isOverBudget ? Colors.redAccent : Colors.greenAccent,
                                    fontSize: 10, fontWeight: FontWeight.bold
                                )
                            ),
                          ),
                          Text(
                              "${(progress * 100).toStringAsFixed(0)}% used of RM ${NumberFormat.compact().format(budgetLimit)}",
                              style: const TextStyle(color: Colors.white70, fontSize: 10)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: progress,
                          backgroundColor: Colors.black26,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? Colors.redAccent : Colors.greenAccent
                          ),
                        ),
                      ),
                    ] else
                      const Text(
                          "No budget set for monthly tracking.",
                          style: TextStyle(color: Colors.white30, fontSize: 12, fontStyle: FontStyle.italic)
                      ),

                    const SizedBox(height: 25),
                    Divider(color: Colors.white.withOpacity(0.2), height: 1),
                    const SizedBox(height: 15),

                    // --- SECONDARY: LIFETIME TOTAL ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "All-Time Total Spending",
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                            Text(
                              "RM $formattedLifetime",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(context, Icons.camera_alt, "Scan Receipt", () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanPage()));
        }),
        _buildActionButton(context, Icons.list_alt, "All Receipts", () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptsListPage()));
        }),
        _buildActionButton(context, Icons.bar_chart, "Reports", () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
        }),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _sectionContainerDecoration(),
      child: FutureBuilder<Map<String, double>>(
        future: FirestoreService().getPaymentMethodTotals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox(
                height: 150,
                child: Center(child: Text("No data yet. Start scanning to see charts!"))
            );
          }

          final methodTotals = snapshot.data!;
          var sortedEntries = methodTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          List<PieChartSectionData> sections = sortedEntries.map((entry) {
            final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: '',
              radius: 50,
              badgeWidget: _Badge(
                entry.key,
                size: 40,
                borderColor: color,
              ),
              badgePositionPercentageOffset: .98,
            );
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Payment Methods (All Time)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 30),

              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    const Center(
                      child: Text("BY\nMETHOD", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              Column(
                children: sortedEntries.map((entry) {
                  final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    child: Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        Text(
                          "RM ${NumberFormat('#,##0.00').format(entry.value)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentReceipts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _sectionContainerDecoration(),
      child: StreamBuilder<List<Receipt>>(
        stream: FirestoreService().getRecentReceiptsStream(3),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }

          final receipts = snapshot.data ?? [];
          if (receipts.isEmpty) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Text('No recent activity.', style: TextStyle(color: Colors.grey)),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptsListPage()));
                      },
                      child: const Text("View All")
                  )
                ],
              ),
              const Divider(),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: receipts.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
                itemBuilder: (context, index) {
                  final receipt = receipts[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E3192).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long, color: Color(0xFF2E3192)),
                    ),
                    title: Text("Via ${receipt.paymentMethod}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(receipt.date)),
                    trailing: Text(
                      '-RM ${receipt.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(context),
            const SizedBox(height: 30),
            _buildQuickActions(context),
            const SizedBox(height: 30),
            _buildChartSection(),
            const SizedBox(height: 25),
            _buildRecentReceipts(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {required this.size, required this.borderColor});
  final String text;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
      child: Center(
        child: Text(
          text.isNotEmpty ? text[0].toUpperCase() : '?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: borderColor),
        ),
      ),
    );
  }
}