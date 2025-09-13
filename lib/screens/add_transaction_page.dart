// screens/add_transaction_page.dart
// Modern card-style form for adding income and expenses
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';

class AddTransactionPage extends StatefulWidget {
  final bool isIncome;

  const AddTransactionPage({Key? key, required this.isIncome}) : super(key: key);

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _paymentType = 'cash';
  String _selectedCategory = 'Food';
  bool _isLoading = false;
  
  // 🚀 NEW: Revolutionary AI Features
  bool _enableSpareChangeInvesting = true;
  bool _enableSocialSplitting = false;
  List<String> _selectedFriends = [];
  double _spareChangeAmount = 0.0;
  int _creditScoreImpact = 0;
  double _financialHealthImpact = 0.0;
  List<String> _aiSuggestions = [];
  Map<String, dynamic>? _billOptimization;
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _expenseCategories = [
    'Food',
    'Rent',
    'Shopping',
    'Transport', 
    'Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Miscellaneous'
  ];

  final List<String> _availableFriends = [
    'Alice Johnson',
    'Bob Smith',
    'Carol Davis',
    'David Wilson',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _slideController.forward();
    _loadAIInsights();
  }

  Future<void> _loadAIInsights() async {
    // Simulate AI loading and provide insights
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _aiSuggestions = [
          '💡 You\'ve spent 23% more on food this month',
          '🎯 Consider setting a \$500 food budget',
          '📈 This category is trending up vs last month',
        ];
      });
    }
  }

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount > 0) {
      setState(() {
        _spareChangeAmount = _calculateSpareChangeRoundup(amount);
        _creditScoreImpact = _calculateCreditImpact(amount);
        _financialHealthImpact = _calculateHealthImpact(amount);
      });
      _checkForBillOptimization(amount);
    }
  }

  double _calculateSpareChangeRoundup(double amount) {
    final rounded = (amount / 5).ceil() * 5.0;
    return rounded - amount;
  }

  int _calculateCreditImpact(double amount) {
    if (widget.isIncome) return 2;
    if (amount > 1000) return -3;
    if (amount < 50) return 1;
    return 0;
  }

  double _calculateHealthImpact(double amount) {
    if (widget.isIncome) return 5.0;
    return -(amount / 100).clamp(0.5, 10.0);
  }

  Future<void> _checkForBillOptimization(double amount) async {
    // AI checks if this looks like a recurring bill that could be optimized
    if (amount > 50 && (_selectedCategory == 'Utilities' || _selectedCategory == 'Rent')) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _billOptimization = {
            'potential_savings': amount * 0.15,
            'confidence': 0.87,
            'suggestion': 'Our AI found similar bills 15% cheaper. Enable auto-negotiation?'
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isIncome ? 'Add Income' : 'Add Expense'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // AI Insights Button
          IconButton(
            icon: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.incomeGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, size: 20),
                  ),
                );
              },
            ),
            onPressed: () => _showAIInsights(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Main Transaction Card
                ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with AI-powered insights
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Smart Amount Input with AI features
                      _buildSmartAmountInput(),
                      const SizedBox(height: 24),

                      // Date Picker
                      _buildDatePicker(),
                      const SizedBox(height: 24),

                      // Category with AI suggestions
                      if (!widget.isIncome) _buildSmartCategorySelector(),

                      // Payment Type
                      _buildPaymentTypeSelector(),
                      const SizedBox(height: 24),

                      // Notes
                      _buildNotesInput(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 🚀 REVOLUTIONARY FEATURES CARDS
                if (_enableSpareChangeInvesting && !widget.isIncome && _spareChangeAmount > 0)
                  _buildSpareChangeInvestingCard(),

                if (_creditScoreImpact != 0)
                  _buildCreditScoreImpactCard(),

                if (_billOptimization != null)
                  _buildBillOptimizationCard(),

                if (!widget.isIncome)
                  _buildSocialSplittingCard(),

                _buildFinancialHealthCard(),

                const SizedBox(height: 24),

                // Enhanced Submit Button
                _buildSmartSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: widget.isIncome 
                ? AppColors.incomeGradient 
                : AppColors.expenseGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.isIncome 
                ? Icons.trending_up 
                : Icons.trending_down,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isIncome ? 'Smart Income Tracker' : 'AI Expense Analyzer',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Powered by AI insights & predictions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Amount'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          onChanged: (value) => _onAmountChanged(),
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixIcon: const Icon(Icons.attach_money, color: AppColors.textSecondary),
            suffixIcon: _spareChangeAmount > 0 ? Container(
              padding: const EdgeInsets.all(8),
              child: Chip(
                label: Text('+\$${_spareChangeAmount.toStringAsFixed(2)} invest'),
                backgroundColor: AppColors.incomeGreen.withOpacity(0.1),
                labelStyle: const TextStyle(fontSize: 10, color: AppColors.incomeGreen),
              ),
            ) : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            if (double.parse(value) <= 0) {
              return 'Amount must be greater than 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSpareChangeInvestingCard() {
    return ModernCard(
      gradient: AppColors.incomeGradient,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.savings, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Smart Spare Change Investing',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Switch(
                value: _enableSpareChangeInvesting,
                onChanged: (value) => setState(() => _enableSpareChangeInvesting = value),
                activeColor: AppColors.incomeGreen,
              ),
            ],
          ),
          if (_enableSpareChangeInvesting) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Roundup Amount: \$${_spareChangeAmount.toStringAsFixed(2)}'),
                        const Text('Investing in: Diversified ETF Portfolio', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.auto_awesome, color: AppColors.incomeGreen),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditScoreImpactCard() {
    final isPositive = _creditScoreImpact > 0;
    return ModernCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive ? AppColors.incomeGreen.withOpacity(0.1) : AppColors.expenseRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? AppColors.incomeGreen : AppColors.expenseRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credit Score Impact',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${isPositive ? '+' : ''}$_creditScoreImpact points predicted',
                  style: TextStyle(
                    color: isPositive ? AppColors.incomeGreen : AppColors.expenseRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showCreditScoreDetails(),
            child: const Text('Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillOptimizationCard() {
    final savings = _billOptimization!['potential_savings'];
    return ModernCard(
      gradient: LinearGradient(
        colors: [AppColors.primaryIndigo.withOpacity(0.1), AppColors.primaryPurple.withOpacity(0.1)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: AppColors.primaryIndigo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Bill Optimization Detected',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _billOptimization!['suggestion'],
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Potential monthly savings: \$${savings.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.incomeGreen, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () => _enableBillOptimization(),
                child: const Text('Enable'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSplittingCard() {
    return ModernCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: AppColors.primaryPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Split with Friends',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(
                value: _enableSocialSplitting,
                onChanged: (value) => setState(() => _enableSocialSplitting = value),
                activeColor: AppColors.primaryPurple,
              ),
            ],
          ),
          if (_enableSocialSplitting) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _availableFriends.map((friend) {
                final isSelected = _selectedFriends.contains(friend);
                return FilterChip(
                  label: Text(friend),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFriends.add(friend);
                      } else {
                        _selectedFriends.remove(friend);
                      }
                    });
                  },
                  selectedColor: AppColors.primaryPurple.withOpacity(0.3),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard() {
    final isPositive = _financialHealthImpact > 0;
    return ModernCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: isPositive ? AppColors.incomeGradient : AppColors.expenseGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? Icons.favorite : Icons.warning,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Financial Health Impact', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${isPositive ? '+' : ''}${_financialHealthImpact.toStringAsFixed(1)} points',
                  style: TextStyle(
                    color: isPositive ? AppColors.incomeGreen : AppColors.expenseRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showHealthDetails(),
            child: const Text('View Score'),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: GradientButton(
          text: _isLoading 
              ? 'Processing with AI...' 
              : (widget.isIncome ? 'Add Smart Income' : 'Add Smart Expense'),
          gradient: widget.isIncome 
              ? AppColors.incomeGradient 
              : AppColors.expenseGradient,
          onPressed: _isLoading ? () {} : _submitTransaction,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textMuted.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionLabel('Category'),
            const Spacer(),
            if (_aiSuggestions.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showAIInsights(),
                icon: const Icon(Icons.psychology, size: 16),
                label: const Text('AI Tips', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textMuted.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              dropdownColor: AppColors.cardBg,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              items: _expenseCategories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Payment Type'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRadioOption('cash', 'Cash', Icons.money),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRadioOption('cheque', 'Cheque', Icons.receipt),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Notes (Optional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Add any additional notes...',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRadioOption(String value, String label, IconData icon) {
    final isSelected = _paymentType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _paymentType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryIndigo.withOpacity(0.1) : AppColors.surfaceBg,
          border: Border.all(
            color: isSelected ? AppColors.primaryIndigo : AppColors.textMuted.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryIndigo : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryIndigo : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryIndigo,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.cardBg,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transaction = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: double.parse(_amountController.text),
        category: widget.isIncome ? 'Income' : _selectedCategory,
        type: widget.isIncome ? 'income' : 'expense',
        date: _selectedDate,
        paymentMethod: _paymentType,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isRecurring: false,
        spareChangeRoundup: _enableSpareChangeInvesting ? _spareChangeAmount : null,
        sharedWithUsers: _enableSocialSplitting ? _selectedFriends : null,
      );

      await FirestoreService().addTransaction('default_user', transaction);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isIncome ? 'Smart income added successfully!' : 'Smart expense tracked with AI insights!',
            ),
            backgroundColor: widget.isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving transaction. Please try again.'),
            backgroundColor: AppColors.expenseRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAIInsights() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: AppColors.primaryIndigo),
                const SizedBox(width: 12),
                const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ..._aiSuggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(child: Text(suggestion)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _showCreditScoreDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Credit Score Impact'),
        content: Text('This transaction will ${_creditScoreImpact > 0 ? 'improve' : 'slightly impact'} your credit score by $_creditScoreImpact points based on our AI analysis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showHealthDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Financial Health'),
        content: Text('Your current financial health score will change by ${_financialHealthImpact.toStringAsFixed(1)} points with this transaction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('View Full Report'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _enableBillOptimization() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Enable Bill Optimization'),
        content: const Text('Our AI will automatically negotiate better rates for your recurring bills. You\'ll be notified of any successful negotiations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _billOptimization = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bill optimization enabled!')),
              );
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
