// screens/home_page.dart
// Ultra-modern finance dashboard with glassmorphism design
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';
import 'transactions_page.dart';
import 'budgeting_page.dart';
import 'reports_page.dart';
import 'add_transaction_page.dart';
import 'credit_cards_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Widget> _pages = [
    const DashboardPage(),
    const TransactionsPage(),
    const BudgetingPage(),
    const ReportsPage(),
    const CreditCardsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.receipt_long_rounded, 'Transactions'),
              _buildNavItem(2, Icons.account_balance_wallet_rounded, 'Budget'),
              _buildNavItem(3, Icons.analytics_rounded, 'Reports'),
              _buildNavItem(4, Icons.credit_card_rounded, 'Cards'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.primaryBlue.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryBlue : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> 
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Financial data
  double cashBalance = 0.0;
  double chequeBalance = 0.0;
  double cashIncome = 0.0;
  double chequeIncome = 0.0;
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double netWorth = 0.0;
  double monthlyBudget = 5000.0;
  
  // Credit cards
  final Map<String, double> creditCardSpending = {
    'amex': 0.0,
    'bofa': 0.0,
    'discover': 0.0,
    'apple_card': 0.0,
    'zolve': 0.0,
  };
  
  Map<String, double> spendingCategories = {};
  List<TransactionModel> transactions = [];
  bool isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      const userId = 'default_user';
      _firestoreService.getTransactions(userId, limit: 100).listen((txList) {
        if (mounted) {
          setState(() {
            transactions = txList;
            _calculateFinancials();
            isLoading = false;
          });
          _animationController.forward();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _calculateFinancials() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    double cash = 0.0;
    double cheque = 0.0;
    double expenses = 0.0;
    Map<String, double> categories = {};
    
    // Reset credit card spending
    for (final key in creditCardSpending.keys) {
      creditCardSpending[key] = 0.0;
    }

    for (final transaction in transactions) {
      if (transaction.date.isAfter(currentMonth) && 
          transaction.date.isBefore(nextMonth)) {
        if (transaction.type == 'income') {
          if (transaction.paymentMethod == 'cash') {
            cash += transaction.amount;
          } else if (transaction.paymentMethod == 'cheque') {
            cheque += transaction.amount;
          }
        } else if (transaction.type == 'expense') {
          expenses += transaction.amount;
          categories[transaction.category] = 
            (categories[transaction.category] ?? 0) + transaction.amount;
          
          if (creditCardSpending.containsKey(transaction.paymentMethod)) {
            creditCardSpending[transaction.paymentMethod] = 
              (creditCardSpending[transaction.paymentMethod] ?? 0) + transaction.amount;
          }
        }
      }
    }

    setState(() {
      cashIncome = cash;
      chequeIncome = cheque;
      totalIncome = cashIncome + chequeIncome;
      totalExpenses = expenses;
      cashBalance = cashIncome - (expenses * 0.4);
      chequeBalance = chequeIncome - (expenses * 0.6);
      netWorth = (cashBalance + chequeBalance) - 
        creditCardSpending.values.fold(0.0, (sum, amount) => sum + amount);
      spendingCategories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildNetWorthCard(),
                    const SizedBox(height: 20),
                    _buildBalanceCards(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildRecentActivity(),
                    const SizedBox(height: 20),
                    _buildSpendingBreakdown(),
                    const SizedBox(height: 100), // Bottom padding for nav
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Your Financial Overview',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ],
    );
  }

  Widget _buildNetWorthCard() {
    final isPositive = netWorth >= 0;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Net Worth',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '${isPositive ? '+' : ''}\$${netWorth.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: isPositive ? AppColors.positiveGreen : AppColors.negativeRed,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive 
              ? 'Great! Your finances are looking healthy'
              : 'Consider reducing expenses or increasing income',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards() {
    return Row(
      children: [
        Expanded(
          child: _buildBalanceCard(
            'Cash',
            cashBalance,
            Icons.money_rounded,
            AppColors.positiveGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildBalanceCard(
            'Bank',
            chequeBalance,
            Icons.account_balance_rounded,
            AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon, Color color) {
    final isPositive = amount >= 0;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: isPositive 
                ? Theme.of(context).textTheme.headlineLarge?.color
                : AppColors.negativeRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add Income',
                Icons.add_rounded,
                AppColors.positiveGreen,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionPage(isIncome: true),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Add Expense',
                Icons.remove_rounded,
                AppColors.negativeRed,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionPage(isIncome: false),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return ModernButton(
      text: text,
      icon: icon,
      backgroundColor: color,
      onPressed: onPressed,
      height: 48,
    );
  }

  Widget _buildRecentActivity() {
    final recentTransactions = transactions.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            TextButton(
              onPressed: () {
                // Navigate to transactions page
              },
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTransactions.isEmpty)
          GlassCard(
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else
          ...recentTransactions.map((transaction) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: _buildTransactionItem(transaction),
          )),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isIncome ? AppColors.positiveGreen : AppColors.negativeRed)
                .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isIncome ? AppColors.positiveGreen : AppColors.negativeRed,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                Text(
                  '${transaction.paymentMethod} • ${_formatDate(transaction.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isIncome ? AppColors.positiveGreen : AppColors.negativeRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingBreakdown() {
    if (spendingCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Breakdown',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            children: spendingCategories.entries.take(5).map((entry) {
              final percentage = totalExpenses > 0 ? entry.value / totalExpenses : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryItem(entry.key, entry.value, percentage),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String category, double amount, double percentage) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppColors.surfaceGray,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                minHeight: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${amount.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    return '${date.month}/${date.day}';
  }
}
