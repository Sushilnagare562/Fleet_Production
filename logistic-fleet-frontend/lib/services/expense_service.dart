import '../core/api_client.dart';
import '../models/expense.dart';

class ExpenseService {
  Future<Expense> addExpense(Expense expense) async {
    final response = await ApiClient.instance.dio.post(
      '/expenses',
      data: expense.toRequestJson(),
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Expense>> getMyExpenses() async {
    final response = await ApiClient.instance.dio.get('/expenses/my');
    return (response.data as List<dynamic>)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // --- Admin ---

  /// Admin logs an expense on a driver's behalf (e.g. a paper receipt);
  /// the backend saves it as already approved.
  Future<Expense> addExpenseForDriver(int driverId, Expense expense) async {
    final response = await ApiClient.instance.dio.post(
      '/admin/expenses',
      data: {
        'driverId': driverId,
        ...expense.toRequestJson(),
      },
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Expense>> getAllExpenses() async {
    final response = await ApiClient.instance.dio.get('/admin/expenses');
    return (response.data as List<dynamic>)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Expense> reviewExpense(int expenseId, String status, {String? reviewNotes}) async {
    final response = await ApiClient.instance.dio.patch(
      '/admin/expenses/$expenseId/status',
      data: {
        'status': status,
        if (reviewNotes != null) 'reviewNotes': reviewNotes,
      },
    );
    return Expense.fromJson(response.data as Map<String, dynamic>);
  }
}
