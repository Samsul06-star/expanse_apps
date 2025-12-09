import 'package:flutter/material.dart';
import '../models/expanse.dart';
import '../services/expanse_api.dart';

class TransactionProvider extends ChangeNotifier {
  final ExpanseService service = ExpanseService();

  List<Expanse> transactions = [];
  bool isLoading = false;

  Future<void> fetchTransactions() async {
    isLoading = true;
    notifyListeners();

    transactions = await service.getAllExpanse();
    isLoading = false;
    notifyListeners();
  }

  void addTransaction(Expanse transaction) {
    transactions.add(transaction);
    notifyListeners();
  }

  // ✅ TAMBAHKAN METHOD INI untuk refresh data setelah add
  Future<void> refreshAfterAdd() async {
    await fetchTransactions();
  }

  double get totalIncome => transactions
      .where((e) =>
          (e.type ?? '').toLowerCase().contains('income') ||
          (e.type ?? '').toLowerCase().contains('in'))
      .fold(0.0, (double sum, item) => sum + item.amount.toDouble());

  double get totalExpenses => transactions
      .where((e) =>
          (e.type ?? '').toLowerCase().contains('expense') ||
          (e.type ?? '').toLowerCase().contains('exp'))
      .fold(0.0, (double sum, item) => sum + item.amount.toDouble());

  double get balance => totalIncome - totalExpenses;

  // update transactions list from a provided list
  void computeFromExpanses(List<Expanse> list) {
    transactions = List<Expanse>.from(list);
    notifyListeners();
  }

  void clear() {
    transactions = [];
    notifyListeners();
  }
}
