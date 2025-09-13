// screens/budgeting_page.dart
// Modern budgeting page with visual progress bars and warning messages
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/budget.dart';
import '../models/transaction.dart';

class BudgetingPage extends StatefulWidget {
  const BudgetingPage({Key? key}) : super(key: key);

  @override
  State<BudgetingPage> createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  final _budgetController = TextEditingController();
  bool _isLoading = false;
  String? _selectedCategory;
  double _monthlyBudget = 0.0;
  
  final Map<String, double> _categoryBudgets = {};

  final Map<String, double> _categorySpent = {};

  @override
  Widget build(BuildContext context) {
    final totalSpent = _categorySpent.values.fold(0.0, (sum, amount) => sum + amount);
    final budgetProgress = _monthlyBudget > 0 ? totalSpent / _monthlyBudget : 0.0;
    final isOverBudget = budgetProgress > 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Budget Overview Card
            ModernCard(
              gradient: isOverBudget ? AppColors.warningGradient : AppColors.primaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Budget',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$${_monthlyBudget.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isOverBudget ? Icons.warning_outlined : Icons.account_balance_wallet_outlined,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBudgetStat('Spent', '\$${totalSpent.toStringAsFixed(2)}'),
                      _buildBudgetStat('Remaining', '\$${(_monthlyBudget - totalSpent).toStringAsFixed(2)}'),
                      _buildBudgetStat('Progress', '${(budgetProgress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Progress bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: budgetProgress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  if (isOverBudget) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_outlined,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You have exceeded your monthly budget by \$${(totalSpent - _monthlyBudget).toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Set Monthly Budget Card
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Monthly Budget',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter monthly budget amount',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      text: _isLoading ? 'Setting...' : 'Set Budget',
                      gradient: AppColors.primaryGradient,
                      onPressed: _isLoading ? () {} : _updateMonthlyBudget,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category Budgets Section
            if (_categoryBudgets.isEmpty) ...[
              ModernCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No category budgets yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by setting your monthly budget and adding categories',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Add Category Budget',
                      icon: Icons.add_circle_outline,
                      gradient: AppColors.primaryGradient,
                      onPressed: _addNewCategoryBudget,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Category Budgets',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Category Budget Cards
              ..._categoryBudgets.entries.map((entry) {
                final category = entry.key;
                final budget = entry.value;
                final spent = _categorySpent[category] ?? 0.0;
                final progress = spent / budget;
                final isOverBudget = progress > 1.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Budget: \$${budget.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${spent.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: isOverBudget ? AppColors.expenseRed : AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: isOverBudget ? AppColors.expenseRed : AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Progress bar
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBg,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isOverBudget 
                                    ? AppColors.expenseGradient 
                                    : progress > 0.8 
                                        ? AppColors.warningGradient 
                                        : AppColors.incomeGradient,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                        if (isOverBudget) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.expenseRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_outlined,
                                  color: AppColors.expenseRed,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Over budget by \$${(spent - budget).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.expenseRed,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (progress > 0.8) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warningYellow.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outlined,
                                  color: AppColors.warningYellow,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Approaching budget limit',
                                  style: const TextStyle(
                                    color: AppColors.warningYellow,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _editCategoryBudget(category, budget),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.primaryIndigo,
                                ),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(color: AppColors.primaryIndigo),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.primaryIndigo),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _deleteCategoryBudget(category),
                                icon: const Icon(
                                  Icons.delete_outlined,
                                  size: 16,
                                  color: AppColors.expenseRed,
                                ),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.expenseRed),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.expenseRed),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Add New Category Budget
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Category Budget',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Add New Category',
                      icon: Icons.add_circle_outline,
                      gradient: AppColors.primaryGradient,
                      onPressed: _addNewCategoryBudget,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _updateMonthlyBudget() async {
    if (_budgetController.text.isEmpty) return;
    
    final newBudget = double.tryParse(_budgetController.text);
    if (newBudget == null || newBudget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Save to Firestore
      setState(() {
        _monthlyBudget = newBudget;
        _budgetController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly budget updated successfully!'),
          backgroundColor: AppColors.incomeGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating budget. Please try again.'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editCategoryBudget(String category, double currentBudget) {
    final controller = TextEditingController(text: currentBudget.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          'Edit $category Budget',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter budget amount',
            prefixIcon: const Icon(
              Icons.attach_money,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          GradientButton(
            text: 'Update',
            gradient: AppColors.primaryGradient,
            width: 80,
            height: 40,
            onPressed: () {
              final newBudget = double.tryParse(controller.text);
              if (newBudget != null && newBudget > 0) {
                setState(() {
                  _categoryBudgets[category] = newBudget;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$category budget updated!'),
                    backgroundColor: AppColors.incomeGreen,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _addNewCategoryBudget() {
    final categoryController = TextEditingController();
    final budgetController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Add New Category Budget',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: categoryController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Category name',
                prefixIcon: Icon(
                  Icons.category_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Budget amount',
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          GradientButton(
            text: 'Add',
            gradient: AppColors.primaryGradient,
            width: 80,
            height: 40,
            onPressed: () {
              final category = categoryController.text.trim();
              final budget = double.tryParse(budgetController.text);
              
              if (category.isNotEmpty && budget != null && budget > 0) {
                setState(() {
                  _categoryBudgets[category] = budget;
                  _categorySpent[category] = 0.0;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$category budget added!'),
                    backgroundColor: AppColors.incomeGreen,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _deleteCategoryBudget(String category) {
    setState(() {
      _categoryBudgets.remove(category);
      _categorySpent.remove(category);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$category budget deleted!'),
        backgroundColor: AppColors.expenseRed,
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
}
