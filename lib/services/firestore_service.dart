// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:financetrack/models/receipt.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _receiptsCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");
    return _db.collection('users').doc(user.uid).collection('receipts');
  }

  // --- Write Operations ---
  Future<void> addReceipt(Receipt receipt) async {
    await _receiptsCollection.add(receipt.toMap());
  }

  Future<void> updateReceipt(Receipt receipt) async {
    if (receipt.id == null) throw Exception("Receipt ID is missing");
    await _receiptsCollection.doc(receipt.id).update(receipt.toMap());
  }

  Future<void> deleteReceipt(Receipt receipt) async {
    if (receipt.id == null) throw Exception("Receipt ID is missing");
    await _receiptsCollection.doc(receipt.id).delete();
  }

  // --- Read Operations ---
  Stream<List<Receipt>> getReceiptsStream({DateTime? startDate, DateTime? endDate}) {
    Query query = _receiptsCollection;
    final dateFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSSSSS");

    if (startDate != null) {
      final startString = dateFormat.format(startDate.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0));
      query = query.where('createdAt', isGreaterThanOrEqualTo: startString);
    }
    if (endDate != null) {
      final endString = dateFormat.format(endDate.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999));
      query = query.where('createdAt', isLessThanOrEqualTo: endString);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Receipt.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  Stream<List<Receipt>> getRecentReceiptsStream(int limit) {
    return _receiptsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Receipt.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // --- Budget & Settings ---
  Future<void> setMonthlyBudget(double amount) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).collection('settings').doc('budget').set({
      'limit': amount,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<double> getMonthlyBudget() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;
    final doc = await _db.collection('users').doc(user.uid).collection('settings').doc('budget').get();
    if (doc.exists && doc.data() != null) {
      return (doc.data()!['limit'] as num).toDouble();
    }
    return 0.0;
  }

  // --- Aggregations ---

  Future<double> getTotalSpent() async {
    final snapshot = await _receiptsCollection.get();
    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
    }
    return total;
  }

  // UPDATED: Calculate spending for a SPECIFIC month provided by UI
  Future<double> getSpecificMonthSpent(DateTime date) async {
    // Start of the selected month
    final startOfMonth = DateTime(date.year, date.month, 1);

    // End of the selected month (Start of next month minus 1 second)
    final endOfMonth = DateTime(date.year, date.month + 1, 1).subtract(const Duration(seconds: 1));

    final startStr = startOfMonth.toIso8601String();
    final endStr = endOfMonth.toIso8601String();

    final snapshot = await _receiptsCollection
        .where('transactionDate', isGreaterThanOrEqualTo: startStr)
        .where('transactionDate', isLessThanOrEqualTo: endStr)
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
    }
    return total;
  }

  Future<Map<String, double>> getPaymentMethodTotals() async {
    final snapshot = await _receiptsCollection.get();
    final Map<String, double> methodTotals = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final method = data['paymentMethod'] as String? ?? 'Cash';
      final amount = double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;

      methodTotals.update(method, (val) => val + amount, ifAbsent: () => amount);
    }
    return methodTotals;
  }
}