class Receipt {
  final String? id;
  final String total;
  final String paymentMethod;
  final String createdAt;
  final String transactionDate;
  final String? localPath;

  Receipt({
    this.id,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
    required this.transactionDate,
    this.localPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'total': total,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
      'transactionDate': transactionDate,
      'localPath': localPath,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> data, String id) {
    return Receipt(
      id: id,
      total: data['total'] ?? '0.00',
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      createdAt: data['createdAt'] ?? DateTime.now().toIso8601String(),
      transactionDate: data['transactionDate'] ?? DateTime.now().toIso8601String(),
      localPath: data['localPath'],
    );
  }

  double get amount => double.tryParse(total) ?? 0.0;
  DateTime get date => DateTime.tryParse(transactionDate) ?? DateTime.now();
}