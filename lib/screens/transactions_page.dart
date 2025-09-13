// screens/transactions_page.dart
// Modern transactions list with advanced filtering and elegant design
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';
import 'add_transaction_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> 
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  
  String _selectedFilter = 'All';
  String _selectedTimeFilter = 'This Month';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = ['All', 'Income', 'Expense'];
  final List<String> _timeFilterOptions = [
    'This Week',
    'This Month', 
    'Last 3 Months',
    'This Year'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _loadTransactions();
    _searchController.addListener(_filterTransactions);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    try {
      const userId = 'default_user';
      _firestoreService.getTransactions(userId, limit: 200).listen((transactions) {
        if (mounted) {
          setState(() {
            _allTransactions = transactions;
            _filterTransactions();
            _isLoading = false;
          });
          _animationController.forward();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterTransactions() {
    List<TransactionModel> filtered = List.from(_allTransactions);
    
    // Apply type filter
    if (_selectedFilter != 'All') {
      filtered = filtered.where((transaction) {
        return transaction.type == _selectedFilter.toLowerCase();
      }).toList();
    }
    
    // Apply time filter
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedTimeFilter) {
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(2020);
    }
    
    filtered = filtered.where((transaction) {
      return transaction.date.isAfter(startDate) || 
             transaction.date.isAtSameMomentAs(startDate);
    }).toList();
    
    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        return transaction.category.toLowerCase().contains(searchQuery) ||
               transaction.paymentMethod.toLowerCase().contains(searchQuery) ||
               (transaction.notes?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }
    
    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      _filteredTransactions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddTransactionModal,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildFiltersSection(),
            Expanded(
              child: _isLoading 
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryBlue),
                  )
                : _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      ..._filterOptions.map((filter) => 
                        _buildFilterChip(filter, _selectedFilter == filter, () {
                          setState(() => _selectedFilter = filter);
                          _filterTransactions();
                        })
                      ),
                      const SizedBox(width: 8),
                      _buildTimeFilterDropdown(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
              ? AppColors.primaryBlue 
              : AppColors.surfaceGray,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTimeFilter,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: Theme.of(context).textTheme.labelMedium,
          dropdownColor: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          items: _timeFilterOptions.map((String time) {
            return DropdownMenuItem<String>(
              value: time,
              child: Text(time),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() => _selectedTimeFilter = newValue!);
            _filterTransactions();
          },
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    // Group transactions by date
    final groupedTransactions = <String, List<TransactionModel>>{};
    for (final transaction in _filteredTransactions) {
      final dateKey = _formatDateKey(transaction.date);
      groupedTransactions.putIfAbsent(dateKey, () => []);
      groupedTransactions[dateKey]!.add(transaction);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final transactions = groupedTransactions[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(dateKey, transactions),
            const SizedBox(height: 12),
            ...transactions.map((transaction) => 
              _buildTransactionCard(transaction)
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String dateKey, List<TransactionModel> transactions) {
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final netAmount = totalIncome - totalExpense;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateKey,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (netAmount != 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (netAmount > 0 
                ? AppColors.positiveGreen 
                : AppColors.negativeRed).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${netAmount > 0 ? '+' : ''}\$${netAmount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: netAmount > 0 
                  ? AppColors.positiveGreen 
                  : AppColors.negativeRed,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isIncome = transaction.type == 'income';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        onTap: () => _showTransactionDetails(transaction),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isIncome 
                  ? AppColors.positiveGreen 
                  : AppColors.negativeRed).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCategoryIcon(transaction.category),
                color: isIncome 
                  ? AppColors.positiveGreen 
                  : AppColors.negativeRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _getPaymentMethodName(transaction.paymentMethod),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (transaction.notes != null) ...[
                        Text(' • ', style: Theme.of(context).textTheme.bodySmall),
                        Expanded(
                          child: Text(
                            transaction.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Amount
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isIncome 
                  ? AppColors.positiveGreen 
                  : AppColors.negativeRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceGray,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions found',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or add a new transaction',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ModernButton(
            text: 'Add Transaction',
            icon: Icons.add_rounded,
            onPressed: _showAddTransactionModal,
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.25,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      text: 'Add Income',
                      icon: Icons.trending_up_rounded,
                      backgroundColor: AppColors.positiveGreen,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => 
                              const AddTransactionPage(isIncome: true),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ModernButton(
                      text: 'Add Expense',
                      icon: Icons.trending_down_rounded,
                      backgroundColor: AppColors.negativeRed,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => 
                              const AddTransactionPage(isIncome: false),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (transaction.type == 'income'
                            ? AppColors.positiveGreen
                            : AppColors.negativeRed).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(transaction.category),
                          color: transaction.type == 'income'
                            ? AppColors.positiveGreen
                            : AppColors.negativeRed,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.category,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              '${transaction.type == 'income' ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: transaction.type == 'income'
                                  ? AppColors.positiveGreen
                                  : AppColors.negativeRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('Payment Method', _getPaymentMethodName(transaction.paymentMethod)),
                  _buildDetailRow('Date', _formatDetailDate(transaction.date)),
                  if (transaction.notes != null)
                    _buildDetailRow('Notes', transaction.notes!),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: 'Edit',
                          isSecondary: true,
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Navigate to edit transaction
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ModernButton(
                          text: 'Delete',
                          backgroundColor: AppColors.negativeRed,
                          onPressed: () => _deleteTransaction(transaction),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ModernButton(
            text: 'Delete',
            backgroundColor: AppColors.negativeRed,
            onPressed: () => Navigator.pop(context, true),
            height: 40,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteTransaction('default_user', transaction.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction deleted successfully'),
              backgroundColor: AppColors.positiveGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete transaction'),
              backgroundColor: AppColors.negativeRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    final iconMap = {
      'Food & Dining': Icons.restaurant_rounded,
      'Transportation': Icons.directions_car_rounded,
      'Shopping': Icons.shopping_bag_rounded,
      'Entertainment': Icons.movie_rounded,
      'Bills & Utilities': Icons.receipt_rounded,
      'Healthcare': Icons.local_hospital_rounded,
      'Groceries': Icons.shopping_cart_rounded,
      'Travel': Icons.flight_rounded,
      'Education': Icons.school_rounded,
      'Salary': Icons.work_rounded,
      'Freelance': Icons.computer_rounded,
      'Business': Icons.business_rounded,
      'Investments': Icons.trending_up_rounded,
      'Rental Income': Icons.home_rounded,
      'Gifts': Icons.card_giftcard_rounded,
    };
    
    return iconMap[category] ?? Icons.category_rounded;
  }

  String _getPaymentMethodName(String method) {
    final nameMap = {
      'amex': 'Amex Card',
      'bofa': 'Bank of America',
      'discover': 'Discover Card',
      'apple_card': 'Apple Card',
      'zolve': 'Zolve Card',
      'cash': 'Cash',
      'cheque': 'Bank Transfer',
      'paypal': 'PayPal',
    };
    
    return nameMap[method] ?? method;
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);
    
    if (transactionDate == today) {
      return 'Today';
    } else if (transactionDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  String _formatDetailDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
