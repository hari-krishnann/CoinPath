import 'package:flutter/foundation.dart';

// models/budget.dart
// Model for user's budget by categories
class BudgetModel extends ChangeNotifier {
  final Map<String, double> categoryBudgets;
  final double monthlyBudget;
  final double? savingsGoal;
  final double? expenses;

  BudgetModel({
    required this.categoryBudgets, 
    required this.monthlyBudget,
    this.savingsGoal, 
    this.expenses
  });

  factory BudgetModel.fromFirestore(Map<String, dynamic> data) {
    return BudgetModel(
      categoryBudgets: Map<String, double>.from(data['category_budgets'] ?? {}),
      monthlyBudget: (data['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      savingsGoal: data['savings_goal'] != null ? (data['savings_goal'] as num).toDouble() : null,
      expenses: data['expenses'] != null ? (data['expenses'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category_budgets': categoryBudgets,
      'monthly_budget': monthlyBudget,
      'savings_goal': savingsGoal,
      'expenses': expenses,
    };
  }
}
