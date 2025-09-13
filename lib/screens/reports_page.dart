// screens/reports_page.dart
// Modern reports page with charts and monthly totals
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';
import '../widgets/chart_widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Real data from transactions
  double monthlyIncome = 0.0;
  double monthlyExpense = 0.0;
  double netBalance = 0.0;
  
  Map<String, double> expenseByCategory = {};
  List<TransactionModel> transactions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTransactionData();
  }

  Future<void> _loadTransactionData() async {
    const userId = 'default_user';
    try {
      // Listen to transaction stream
      _firestoreService.getTransactions(userId, limit: 100).listen((transactionList) {
        setState(() {
          transactions = transactionList;
          _calculateMonthlyData();
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

  void _calculateMonthlyData() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    double income = 0.0;
    double expense = 0.0;
    Map<String, double> categoryTotals = {};

    for (final transaction in transactions) {
      // Only include transactions from current month
      if (transaction.date.isAfter(currentMonth) && transaction.date.isBefore(nextMonth)) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else if (transaction.type == 'expense') {
          expense += transaction.amount;
          
          // Calculate category totals
          final category = transaction.category;
          categoryTotals[category] = (categoryTotals[category] ?? 0) + transaction.amount;
        }
      }
    }

    monthlyIncome = income;
    monthlyExpense = expense;
    netBalance = income - expense;
    expenseByCategory = categoryTotals;
  }

  List<double> _getMonthlyIncomeData() {
    final now = DateTime.now();
    List<double> incomeData = [];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(now.year, now.month - i + 1);
      
      double monthIncome = 0;
      for (final transaction in transactions) {
        if (transaction.type == 'income' && 
            transaction.date.isAfter(month) && 
            transaction.date.isBefore(nextMonth)) {
          monthIncome += transaction.amount;
        }
      }
      incomeData.add(monthIncome);
    }
    
    return incomeData;
  }

  List<double> _getMonthlyExpenseData() {
    final now = DateTime.now();
    List<double> expenseData = [];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      final nextMonth = DateTime(now.year, now.month - i + 1);
      
      double monthExpense = 0;
      for (final transaction in transactions) {
        if (transaction.type == 'expense' && 
            transaction.date.isAfter(month) && 
            transaction.date.isBefore(nextMonth)) {
          monthExpense += transaction.amount;
        }
      }
      expenseData.add(monthExpense);
    }
    
    return expenseData;
  }

  List<String> _getMonthLabels() {
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    List<String> labels = [];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i);
      labels.add(monthNames[month.month - 1]);
    }
    
    return labels;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reports & Analytics'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
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
            // Monthly Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Income',
                    '\$${monthlyIncome.toStringAsFixed(2)}',
                    Icons.trending_up,
                    AppColors.incomeGradient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Expense',
                    '\$${monthlyExpense.toStringAsFixed(2)}',
                    Icons.trending_down,
                    AppColors.expenseGradient,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              'Net Balance',
              '\$${netBalance.toStringAsFixed(2)}',
              netBalance >= 0 ? Icons.account_balance_wallet : Icons.warning,
              netBalance >= 0 ? AppColors.primaryGradient : AppColors.warningGradient,
              isFullWidth: true,
            ),

            const SizedBox(height: 32),

            // Show Income Flow Visualization if there are transactions
            if (transactions.isNotEmpty) ...[
              Text(
                'Income Flow Visualization',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              IncomeSankeyDiagram(
                transactions: transactions,
                height: 300,
              ),
              const SizedBox(height: 32),
            ],

            // No Data State or Charts Section
            if (monthlyIncome == 0 && monthlyExpense == 0) ...[
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
                        Icons.analytics_outlined,
                        size: 48,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No data to analyze yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start adding transactions to see detailed reports and analytics',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    GradientButton(
                      text: 'Add Transaction',
                      icon: Icons.add_circle_outline,
                      gradient: AppColors.primaryGradient,
                      onPressed: () {
                        // Navigate to add transaction page
                        Navigator.pushNamed(context, '/add-transaction');
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Charts Section (only show if there's data)
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),

              // Tab Bar for Charts
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textMuted,
                  tabs: const [
                    Tab(text: 'Trends'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Comparison'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Chart Content
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTrendsChart(),
                    _buildCategoryChart(),
                    _buildComparisonChart(),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Category Breakdown (only show if there's data)
              if (expenseByCategory.isNotEmpty) ...[
                Text(
                  'Expense Breakdown',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                ...expenseByCategory.entries.map((entry) {
                  final category = entry.key;
                  final amount = entry.value;
                  final percentage = monthlyExpense > 0 ? (amount / monthlyExpense * 100) : 0.0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ModernCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${percentage.toStringAsFixed(1)}% of total expenses',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    IconData icon,
    Gradient gradient, {
    bool isFullWidth = false,
  }) {
    return ModernCard(
      gradient: gradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                icon,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isFullWidth ? 28 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart() {
    final incomeData = _getMonthlyIncomeData();
    final expenseData = _getMonthlyExpenseData();
    final monthLabels = _getMonthLabels();

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Income vs Expense Trend',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: IncomeExpenseBarChart(
              incomeData: incomeData,
              expenseData: expenseData,
              months: monthLabels,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('Income', AppColors.incomeGreen),
              const SizedBox(width: 24),
              _buildChartLegend('Expense', AppColors.expenseRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expense by Category',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: expenseByCategory.isNotEmpty 
              ? CategoryPieChart(categoryData: expenseByCategory)
              : const Center(
                  child: Text(
                    'No expense data available',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    final incomeData = _getMonthlyIncomeData();
    final expenseData = _getMonthlyExpenseData();
    final monthLabels = _getMonthLabels();
    final maxValue = [...incomeData, ...expenseData].fold(0.0, (a, b) => a > b ? a : b);

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Comparison',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue > 0 ? maxValue * 1.2 : 1000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              monthLabels[value.toInt()],
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
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
                barGroups: List.generate(monthLabels.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: incomeData[index],
                        gradient: AppColors.incomeGradient,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: expenseData[index],
                        gradient: AppColors.expenseGradient,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('Income', AppColors.incomeGreen),
              const SizedBox(width: 24),
              _buildChartLegend('Expense', AppColors.expenseRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
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

  Color _getCategoryColor(String category) {
    final colors = [
      AppColors.primaryIndigo,
      AppColors.primaryPurple,
      AppColors.primaryPink,
      AppColors.incomeGreen,
      AppColors.expenseRed,
      AppColors.warningYellow,
      AppColors.cashRed,
      AppColors.chequeBlue,
    ];
    
    final index = expenseByCategory.keys.toList().indexOf(category);
    return colors[index % colors.length];
  }
}
