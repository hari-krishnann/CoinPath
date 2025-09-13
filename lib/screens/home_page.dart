// screens/home_page.dart
// Modern professional finance dashboard with bottom navigation
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';
import 'transactions_page.dart';
import 'budgeting_page.dart';
import 'reports_page.dart';
import 'add_transaction_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    TransactionsPage(),
    BudgetingPage(),
    ReportsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cardBg,
          selectedItemColor: AppColors.primaryIndigo,
          unselectedItemColor: AppColors.textMuted,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Real data from transactions
  double cashIncome = 0.0;
  double chequeIncome = 0.0;
  double totalExpenses = 0.0;
  double monthlyBudget = 0.0;
  
  List<TransactionModel> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactionData();
  }

  Future<void> _loadTransactionData() async {
    const userId = 'default_user';
    try {
      // Listen to transaction stream
      _firestoreService.getTransactions(userId, limit: 100).listen((transactionList) {
        setState(() {
          transactions = transactionList;
          _calculateDashboardData();
          isLoading = false;
        });
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateDashboardData() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    double cash = 0.0;
    double cheque = 0.0;
    double expenses = 0.0;

    for (final transaction in transactions) {
      // Only include transactions from current month
      if (transaction.date.isAfter(currentMonth) && transaction.date.isBefore(nextMonth)) {
        if (transaction.type == 'income') {
          if (transaction.paymentMethod == 'cash') {
            cash += transaction.amount;
          } else {
            cheque += transaction.amount;
          }
        } else if (transaction.type == 'expense') {
          expenses += transaction.amount;
        }
      }
    }

    cashIncome = cash;
    chequeIncome = cheque;
    totalExpenses = expenses;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalIncome = cashIncome + chequeIncome;
    final remainingBudget = monthlyBudget - totalExpenses;
    final budgetUsedPercentage = monthlyBudget > 0 ? (totalExpenses / monthlyBudget).clamp(0.0, 1.0) : 0.0;
    final maxIncomeValue = [cashIncome, chequeIncome].fold(0.0, (a, b) => a > b ? a : b);
    final chartMaxY = maxIncomeValue > 0 ? maxIncomeValue * 1.2 : 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactionData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Income Summary Card
            ModernCard(
              gradient: AppColors.primaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Income',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'This Month',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '\$${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Cash: \$${cashIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Cheque: \$${chequeIncome.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Income Overview Chart Card
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Income Breakdown',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: totalIncome > 0 ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMaxY,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => AppColors.cardBg,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final value = rod.toY;
                              final type = groupIndex == 0 ? 'Cash' : 'Cheque';
                              return BarTooltipItem(
                                '$type\n\$${value.toStringAsFixed(2)}',
                                const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
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
                                const style = TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                );
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text('Cash', style: style);
                                  case 1:
                                    return const Text('Cheque', style: style);
                                  default:
                                    return const Text('', style: style);
                                }
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: cashIncome,
                                gradient: const LinearGradient(
                                  colors: [AppColors.cashRed, Color(0xFFFF6B6B)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 40,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: chequeIncome,
                                gradient: const LinearGradient(
                                  colors: [AppColors.chequeBlue, Color(0xFF4F9EF8)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 40,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ) : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBg.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textMuted.withOpacity(0.2),
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Income Data',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add income transactions to see breakdown',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (totalIncome > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildLegendItem('Cash', AppColors.cashRed),
                        const SizedBox(width: 24),
                        _buildLegendItem('Cheque', AppColors.chequeBlue),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Budget Overview Card
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget Overview',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (monthlyBudget == 0)
                        TextButton(
                          onPressed: () {
                            // Navigate to budget setup
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BudgetingPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Set Budget',
                            style: TextStyle(
                              color: AppColors.primaryIndigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (monthlyBudget > 0) ...[
                    _buildBudgetRow('Monthly Budget', '\$${monthlyBudget.toStringAsFixed(2)}', AppColors.textSecondary),
                    const SizedBox(height: 16),
                    _buildBudgetRow('Amount Spent', '\$${totalExpenses.toStringAsFixed(2)}', AppColors.expenseRed),
                    const SizedBox(height: 16),
                    _buildBudgetRow('Remaining', '\$${remainingBudget.toStringAsFixed(2)}', 
                        remainingBudget >= 0 ? AppColors.incomeGreen : AppColors.expenseRed),
                    const SizedBox(height: 24),
                    // Progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: budgetUsedPercentage,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: budgetUsedPercentage > 0.8 
                                ? AppColors.warningGradient 
                                : budgetUsedPercentage > 0.6
                                    ? AppColors.expenseGradient
                                    : AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(budgetUsedPercentage * 100).toStringAsFixed(1)}% of budget used',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBg.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textMuted.withOpacity(0.2),
                        ),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Budget Set',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Set up a monthly budget to track your spending',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Action Buttons
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: 'Add Income',
                    icon: Icons.add_circle_outline,
                    gradient: AppColors.incomeGradient,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionPage(isIncome: true),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    text: 'Add Expense',
                    icon: Icons.remove_circle_outline,
                    gradient: AppColors.expenseGradient,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddTransactionPage(isIncome: false),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetRow(String label, String amount, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
