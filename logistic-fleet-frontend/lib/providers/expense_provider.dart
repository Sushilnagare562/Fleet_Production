import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _loading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get loading => _loading;
  String? get error => _error;

  double get totalThisMonth {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> loadMyExpenses() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _expenses = await _expenseService.getMyExpenses();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      final created = await _expenseService.addExpense(expense);
      _expenses.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // --- Admin ---

  List<Expense> _allExpenses = [];
  List<Expense> get allExpenses => _allExpenses;
  List<Expense> get pendingExpenses => _allExpenses.where((e) => e.status == 'PENDING').toList();

  Future<void> loadAllExpenses() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _allExpenses = await _expenseService.getAllExpenses();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Admin logs an expense on behalf of a driver (e.g. a paper receipt).
  /// The backend saves it pre-approved, so it lands directly in the
  /// approvals list without needing a separate review step.
  Future<bool> addExpenseForDriver(int driverId, Expense expense) async {
    try {
      final created = await _expenseService.addExpenseForDriver(driverId, expense);
      _allExpenses.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> reviewExpense(int expenseId, String status, {String? reviewNotes}) async {
    try {
      final updated = await _expenseService.reviewExpense(expenseId, status, reviewNotes: reviewNotes);
      final index = _allExpenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        _allExpenses[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = ApiClient.errorMessage(e);
      notifyListeners();
    }
  }
}
