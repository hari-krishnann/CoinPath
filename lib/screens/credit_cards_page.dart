// screens/credit_cards_page.dart
// Credit card management and payment tracking dashboard
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({Key? key}) : super(key: key);

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  List<TransactionModel> transactions = [];
  bool isLoading = true;
  
  // Credit card data structure
  final Map<String, Map<String, dynamic>> _creditCards = {
    'amex': {
      'name': 'Amex Card',
      'color': Color(0xFF006FCF),
      'icon': Icons.credit_card,
      'balance': 0.0,
      'limit': 5000.0,
      'dueDate': DateTime.now().add(Duration(days: 15)),
      'lastPayment': 0.0,
      'monthlySpending': 0.0,
    },
    'bofa': {
      'name': 'Bank of America',
      'color': Color(0xFFE31837),
      'icon': Icons.credit_card,
      'balance': 0.0,
      'limit': 8000.0,
      'dueDate': DateTime.now().add(Duration(days: 20)),
      'lastPayment': 0.0,
      'monthlySpending': 0.0,
    },
    'discover': {
      'name': 'Discover Card',
      'color': Color(0xFFFF6000),
      'icon': Icons.credit_card,
      'balance': 0.0,
      'limit': 6000.0,
      'dueDate': DateTime.now().add(Duration(days: 25)),
      'lastPayment': 0.0,
      'monthlySpending': 0.0,
    },
    'apple_card': {
      'name': 'Apple Card',
      'color': Color(0xFF1D1D1F),
      'icon': Icons.credit_card,
      'balance': 0.0,
      'limit': 4000.0,
      'dueDate': DateTime.now().add(Duration(days: 10)),
      'lastPayment': 0.0,
      'monthlySpending': 0.0,
    },
    'zolve': {
      'name': 'Zolve Card',
      'color': Color(0xFF6B46C1),
      'icon': Icons.credit_card,
      'balance': 0.0,
      'limit': 3000.0,
      'dueDate': DateTime.now().add(Duration(days: 18)),
      'lastPayment': 0.0,
      'monthlySpending': 0.0,
    },
  };

  double totalCashIncome = 0.0;
  double totalChequeIncome = 0.0;
  double totalCreditSpending = 0.0;
  double totalOutstanding = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactionData();
  }

  Future<void> _loadTransactionData() async {
    const userId = 'default_user';
    try {
      _firestoreService.getTransactions(userId, limit: 300).listen((transactionList) {
        setState(() {
          transactions = transactionList;
          _calculateCardBalances();
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

  void _calculateCardBalances() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    // Reset calculations
    totalCashIncome = 0.0;
    totalChequeIncome = 0.0;
    totalCreditSpending = 0.0;
    totalOutstanding = 0.0;

    // Reset card balances
    for (var card in _creditCards.keys) {
      _creditCards[card]!['monthlySpending'] = 0.0;
      _creditCards[card]!['balance'] = 0.0;
    }

    // Process transactions
    for (final transaction in transactions) {
      if (transaction.date.isAfter(currentMonth) && transaction.date.isBefore(nextMonth)) {
        if (transaction.type == 'income') {
          if (transaction.paymentMethod == 'cash') {
            totalCashIncome += transaction.amount;
          } else if (transaction.paymentMethod == 'cheque') {
            totalChequeIncome += transaction.amount;
          }
        } else if (transaction.type == 'expense') {
          if (_creditCards.containsKey(transaction.paymentMethod)) {
            _creditCards[transaction.paymentMethod]!['monthlySpending'] += transaction.amount;
            _creditCards[transaction.paymentMethod]!['balance'] += transaction.amount;
            totalCreditSpending += transaction.amount;
          }
        }
      }
    }

    // Calculate total outstanding
    totalOutstanding = _creditCards.values.fold(0.0, (sum, card) => sum + card['balance']);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Credit Cards'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryIndigo),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Cards'),
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
            // Financial Overview Card
            _buildFinancialOverview(),
            const SizedBox(height: 24),

            // Income Sources
            _buildIncomeSourcesCard(),
            const SizedBox(height: 24),

            // Credit Cards Grid
            Text(
              'Your Credit Cards',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            ..._creditCards.entries.map((entry) => 
              _buildCreditCardCard(entry.key, entry.value)
            ).toList(),

            const SizedBox(height: 24),

            // Payment Schedule
            _buildPaymentSchedule(),
            
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final totalIncome = totalCashIncome + totalChequeIncome;
    final availableForPayments = totalIncome - totalOutstanding;
    final utilizationRate = totalOutstanding / (totalIncome > 0 ? totalIncome : 1);

    return ModernCard(
      gradient: utilizationRate > 0.8 ? AppColors.warningGradient : AppColors.primaryGradient,
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
                    'Monthly Overview',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Total Income: \$${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
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
                  utilizationRate > 0.8 ? Icons.warning_outlined : Icons.account_balance_wallet_outlined,
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
              _buildOverviewStat('Credit Spending', '\$${totalCreditSpending.toStringAsFixed(2)}'),
              _buildOverviewStat('Outstanding', '\$${totalOutstanding.toStringAsFixed(2)}'),
              _buildOverviewStat('Available', '\$${availableForPayments.toStringAsFixed(2)}'),
            ],
          ),
          if (utilizationRate > 0.8) ...[
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
                      'High utilization rate (${(utilizationRate * 100).toStringAsFixed(0)}%). Consider paying down balances.',
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
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
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

  Widget _buildIncomeSourcesCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.incomeGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                'Income Sources',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildIncomeSourceTile(
                  'Cash Income',
                  totalCashIncome,
                  AppColors.cashRed,
                  Icons.money,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIncomeSourceTile(
                  'Cheque Income',
                  totalChequeIncome,
                  AppColors.chequeBlue,
                  Icons.account_balance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeSourceTile(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardCard(String cardId, Map<String, dynamic> cardData) {
    final balance = cardData['balance'] as double;
    final limit = cardData['limit'] as double;
    final utilization = limit > 0 ? balance / limit : 0.0;
    final dueDate = cardData['dueDate'] as DateTime;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ModernCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cardData['color'].withOpacity(0.2), cardData['color'].withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    cardData['icon'],
                    color: cardData['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cardData['name'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Due: ${dueDate.day}/${dueDate.month} (${daysUntilDue} days)',
                        style: TextStyle(
                          color: daysUntilDue <= 7 ? AppColors.expenseRed : AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: utilization > 0.8 ? AppColors.expenseRed : AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${(utilization * 100).toStringAsFixed(0)}% used',
                      style: TextStyle(
                        color: utilization > 0.8 ? AppColors.expenseRed : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Utilization bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Utilization: \$${balance.toStringAsFixed(0)} / \$${limit.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'Monthly: \$${cardData['monthlySpending'].toStringAsFixed(0)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBg,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: utilization.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: utilization > 0.8
                            ? AppColors.expenseGradient
                            : utilization > 0.6
                                ? AppColors.warningGradient
                                : AppColors.incomeGradient,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAsPaid(cardId),
                    icon: Icon(
                      Icons.payment,
                      size: 16,
                      color: cardData['color'],
                    ),
                    label: Text(
                      'Mark Paid',
                      style: TextStyle(color: cardData['color']),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cardData['color']),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewCardDetails(cardId),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppColors.primaryIndigo,
                    ),
                    label: const Text(
                      'Details',
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSchedule() {
    final sortedCards = _creditCards.entries.toList()
      ..sort((a, b) => a.value['dueDate'].compareTo(b.value['dueDate']));

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppColors.primaryIndigo, size: 24),
              const SizedBox(width: 12),
              Text(
                'Payment Schedule',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedCards.map((entry) {
            final cardData = entry.value;
            final dueDate = cardData['dueDate'] as DateTime;
            final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
            final balance = cardData['balance'] as double;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: daysUntilDue <= 7 
                    ? AppColors.expenseRed.withOpacity(0.1)
                    : AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: daysUntilDue <= 7 
                      ? AppColors.expenseRed.withOpacity(0.3)
                      : AppColors.textMuted.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cardData['icon'],
                    color: cardData['color'],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardData['name'],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: daysUntilDue <= 7 ? AppColors.expenseRed : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${daysUntilDue} days',
                        style: TextStyle(
                          color: daysUntilDue <= 7 ? AppColors.expenseRed : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return ModernCard(
      child: Column(
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
                child: GradientButton(
                  text: 'Pay All Cards',
                  icon: Icons.payment,
                  gradient: AppColors.incomeGradient,
                  onPressed: _payAllCards,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GradientButton(
                  text: 'Set Reminders',
                  icon: Icons.notifications,
                  gradient: AppColors.primaryGradient,
                  onPressed: _setReminders,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _markAsPaid(String cardId) {
    final balance = _creditCards[cardId]!['balance'] as double;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          'Mark ${_creditCards[cardId]!['name']} as Paid',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Mark \$${balance.toStringAsFixed(2)} as paid?',
          style: const TextStyle(color: AppColors.textSecondary),
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
            text: 'Mark Paid',
            gradient: AppColors.incomeGradient,
            onPressed: () {
              setState(() {
                _creditCards[cardId]!['balance'] = 0.0;
                _creditCards[cardId]!['lastPayment'] = balance;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_creditCards[cardId]!['name']} marked as paid!'),
                  backgroundColor: AppColors.incomeGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _viewCardDetails(String cardId) {
    // Navigate to detailed card view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${_creditCards[cardId]!['name']}'),
        backgroundColor: AppColors.primaryIndigo,
      ),
    );
  }

  void _payAllCards() {
    final totalToPay = _creditCards.values.fold(0.0, (sum, card) => sum + card['balance']);
    final totalIncome = totalCashIncome + totalChequeIncome;
    
    if (totalToPay > totalIncome) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient income to pay all cards this month'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text(
          'Pay All Credit Cards',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Pay total of \$${totalToPay.toStringAsFixed(2)} across all cards?',
          style: const TextStyle(color: AppColors.textSecondary),
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
            text: 'Pay All',
            gradient: AppColors.incomeGradient,
            onPressed: () {
              setState(() {
                for (var cardId in _creditCards.keys) {
                  _creditCards[cardId]!['lastPayment'] = _creditCards[cardId]!['balance'];
                  _creditCards[cardId]!['balance'] = 0.0;
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All credit cards paid successfully!'),
                  backgroundColor: AppColors.incomeGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _setReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment reminders set for all cards'),
        backgroundColor: AppColors.primaryIndigo,
      ),
    );
  }
}