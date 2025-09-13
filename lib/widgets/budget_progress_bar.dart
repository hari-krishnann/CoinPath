// widgets/budget_progress_bar.dart
// Widget to show budget progress as a bar
import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double budget;

  const BudgetProgressBar({Key? key, required this.spent, required this.budget}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final overBudget = spent > budget;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget: ${spent.toStringAsFixed(2)} / ${budget.toStringAsFixed(2)}'),
        SizedBox(height: 4),
        AnimatedContainer(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              overBudget ? Colors.red : Colors.indigo,
            ),
          ),
        ),
        if (overBudget)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Over budget!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
