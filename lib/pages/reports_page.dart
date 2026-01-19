// lib/reports_page.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure this is in pubspec.yaml
import 'package:intl/intl.dart';
import 'package:financetrack/services/firestore_service.dart';
import 'package:financetrack/models/receipt.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final primaryColor = const Color(0xFF2E3192);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Monthly Reports", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Receipt>>(
        // Retrieve ALL receipts so we can group them
        stream: FirestoreService().getReceiptsStream(), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final receipts = snapshot.data ?? [];
          if (receipts.isEmpty) {
            return const Center(child: Text("No receipts found."));
          }

          // --- LOGIC: PROCESS DATA ---
          // 1. Group by Month (Key: '2025-12', Value: Total)
          // We use a Map to sum up totals.
          final Map<String, double> monthlyTotals = {};
          
          for (var r in receipts) {
            // Format Key as "YYYY-MM" for easy sorting
            String key = DateFormat('yyyy-MM').format(r.date); 
            monthlyTotals[key] = (monthlyTotals[key] ?? 0) + r.amount;
          }

          // 2. Sort the keys (Newest Month First)
          final sortedKeys = monthlyTotals.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Descending order (2025-12 before 2025-01)

          // 3. Prepare data for the Chart (Take top 6 months max to fit screen)
          final chartKeys = sortedKeys.take(6).toList().reversed.toList(); // Reverse for chart (Old -> New)
          
          // Max value for chart scaling
          double maxVal = 0;
          for(var k in chartKeys) {
             if (monthlyTotals[k]! > maxVal) maxVal = monthlyTotals[k]!;
          }
          if (maxVal == 0) maxVal = 100; // prevent div by zero

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- BAR CHART SECTION ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Spending Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Last 6 Months", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 30),
                      AspectRatio(
                        aspectRatio: 1.5,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxVal * 1.2, // Add some headroom
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.blueGrey,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    'RM ${rod.toY.toStringAsFixed(0)}',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < chartKeys.length) {
                                      // Convert "2023-12" to "Dec"
                                      String key = chartKeys[value.toInt()];
                                      DateTime date = DateFormat('yyyy-MM').parse(key);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('MMM').format(date),
                                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: chartKeys.asMap().entries.map((entry) {
                              int index = entry.key;
                              String key = entry.value;
                              double amount = monthlyTotals[key] ?? 0;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: amount,
                                    color: primaryColor,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: maxVal * 1.2,
                                      color: Colors.grey[100],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // --- DETAILED LIST SECTION ---
                const Text("History by Month", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    String key = sortedKeys[index]; // "2023-12"
                    double amount = monthlyTotals[key]!;
                    DateTime date = DateFormat('yyyy-MM').parse(key);
                    String prettyDate = DateFormat('MMMM yyyy').format(date); // "December 2023"

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month, color: Color(0xFF2E3192)),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prettyDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Total Spent", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(
                            "RM ${NumberFormat('#,##0.00').format(amount)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}