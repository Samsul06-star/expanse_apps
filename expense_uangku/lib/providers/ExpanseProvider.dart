import 'package:expense_uangku/routes/app_routes.dart';
import 'package:expense_uangku/services/expanse_api.dart';
import 'package:flutter/material.dart';
import '../models/expanse.dart';

class ExpanseProvider extends ChangeNotifier {
  final ExpanseService service = ExpanseService();

  List<Expanse> expenses = [];
  bool isLoading = false;

  List<Expanse> get latestThree {
    final sorted = List<Expanse>.from(expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(3).toList();
  }

  Future<void> fetchAllExpanse() async {
    isLoading = true;
    notifyListeners();
    expenses = await service.getAllExpanse();
    isLoading = false;
    notifyListeners();
  }

  void clear() {
    expenses = [];
    notifyListeners();
  }

  // ✅ TAMBAHKAN METHOD INI
  Future<bool> addExpanse({
    required String category,
    required String type,
    required int amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      final result = await service.addExpanse(
        category,
        type,
        amount,
        description,
        date,
      );

      if (result != null) {
        // Tambah ke list lokal di posisi pertama (terbaru)
        expenses.insert(0, result);
        notifyListeners(); // ✅ Update UI otomatis
        return true;
      }
      return false;
    } catch (e) {
      print("Error adding expanse: $e");
      return false;
    }
  }

  Future<bool> updateExpanse(int id, Expanse updatedData) async {
    try {
      final result = await service.updateExpanse(id, updatedData);

      if (result != null) {
        // Update data di list lokal
        final index = expenses.indexWhere((e) => e.id == id);
        if (index != -1) {
          expenses[index] = result;
          notifyListeners(); // ✅ Update UI otomatis
        }
        return true;
      }
      return false;
    } catch (e) {
      print("Error updating expanse: $e");
      return false;
    }
  }

  Future<bool> deleteExpanse(int id) async {
    try {
      final success = await service.deleteExpanse(id);

      if (success) {
        // Hapus dari list lokal
        expenses.removeWhere((e) => e.id == id);
        notifyListeners(); // ✅ Update UI otomatis
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting expanse: $e");
      return false;
    }
  }

  void listenAuth(AuthNotifier auth) {
    auth.addListener(() {
      if (auth.isLoggedIn) {
        fetchAllExpanse();
      } else {
        clear();
      }
    });
  }
}
