// screens/financial_health_page.dart
// 🚀 REVOLUTIONARY FEATURE 5: Predictive Financial Health Scoring Dashboard
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';

class FinancialHealthPage extends StatefulWidget {
  const FinancialHealthPage({Key? key}) : super(key: key);

  @override
  _FinancialHealthPageState createState() => _FinancialHealthPageState();
}

class _FinancialHealthPageState extends State<FinancialHealthPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  
  FinancialHealthModel? _healthData;
  bool _isLoading = true;
  double _currentScore = 742;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _loadHealthData();
    _controller.forward();
  }

  Future<void> _loadHealthData() async {
    try {
      final healthData = await FirestoreService().getFinancialHealth('default_user');
      setState(() {
        _healthData = healthData;
        _currentScore = healthData.currentScore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Health'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshHealthScore(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHealthScoreCard(),
                    const SizedBox(height: 16),
                    _buildCategoryBreakdown(),
                    const SizedBox(height: 16),
                    _buildPredictiveInsights(),
                    const SizedBox(height: 16),
                    _buildRiskAlerts(),
                    const SizedBox(height: 16),
                    _buildOpportunities(),
                    const SizedBox(height: 16),
                    _buildHealthTrend(),
                    const SizedBox(height: 16),
                    _buildActionPlan(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthScoreCard() {
    final scoreColor = _getScoreColor(_currentScore);
    final scoreGrade = _getScoreGrade(_currentScore);
    
    return ModernCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scoreColor.withOpacity(0.1),
          scoreColor.withOpacity(0.05),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [scoreColor.withOpacity(0.3), scoreColor.withOpacity(0.1)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite, color: scoreColor, size: 32),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Health Score',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${_currentScore.toInt()}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        const Text('/1000', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            scoreGrade,
                            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getScoreDescription(_currentScore),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildScoreBar(),
        ],
      ),
    );
  }

  Widget _buildScoreBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Poor', style: TextStyle(fontSize: 12, color: Colors.red.withOpacity(0.7))),
            Text('Fair', style: TextStyle(fontSize: 12, color: Colors.orange.withOpacity(0.7))),
            Text('Good', style: TextStyle(fontSize: 12, color: Colors.yellow.withOpacity(0.7))),
            Text('Excellent', style: TextStyle(fontSize: 12, color: Colors.green.withOpacity(0.7))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green],
            ),
          ),
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * (_currentScore / 1000) * 0.85,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _getScoreColor(_currentScore), width: 2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown() {
    final categories = {
      'Spending': 0.85,
      'Savings': 0.72,
      'Debt': 0.68,
      'Investment': 0.91,
      'Emergency Fund': 0.45,
    };

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Category Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...categories.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '${(entry.value * 100).toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(entry.value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: entry.value,
                  backgroundColor: AppColors.textMuted.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.value)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPredictiveInsights() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primaryIndigo),
              const SizedBox(width: 12),
              const Text(
                'AI Predictive Insights',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            '📈 Score Projection',
            'Your financial health score is predicted to reach 785 within 3 months',
            'Based on current spending trends',
            AppColors.incomeGreen,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            '💰 Savings Goal',
            'You\'re on track to save \$2,450 more this year',
            'Continue current budget discipline',
            AppColors.primaryIndigo,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            '🎯 Emergency Fund',
            'Build your emergency fund by 65% in 6 months',
            'Increase monthly savings by \$200',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, String action, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(action, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRiskAlerts() {
    final risks = [
      {
        'title': '⚠️ High Spending Alert',
        'description': 'Food expenses up 23% this month',
        'severity': 'medium',
        'action': 'Set a food budget limit',
      },
      {
        'title': '🔴 Emergency Fund Low',
        'description': 'Only covers 1.2 months of expenses',
        'severity': 'high',
        'action': 'Increase emergency savings',
      },
    ];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Risk Alerts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...risks.map((risk) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildRiskCard(risk),
          )),
        ],
      ),
    );
  }

  Widget _buildRiskCard(Map<String, String> risk) {
    final color = risk['severity'] == 'high' ? AppColors.expenseRed : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(risk['title']!, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(risk['description']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(risk['action']!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleRiskAction(risk),
            child: const Text('Fix'),
          ),
        ],
      ),
    );
  }

  Widget _buildOpportunities() {
    final opportunities = [
      {
        'title': '💡 Investment Opportunity',
        'description': 'Market dip detected - consider increasing investments',
        'value': '+\$1,200 potential gain',
      },
      {
        'title': '🏦 Better Savings Rate',
        'description': 'Found accounts with 2.1% higher interest rates',
        'value': '+\$340 yearly interest',
      },
      {
        'title': '💳 Credit Card Rewards',
        'description': 'Switch to cashback card for your spending pattern',
        'value': '+\$480 yearly rewards',
      },
    ];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: AppColors.incomeGreen),
              const SizedBox(width: 12),
              const Text(
                'Financial Opportunities',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...opportunities.map((opp) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildOpportunityCard(opp),
          )),
        ],
      ),
    );
  }

  Widget _buildOpportunityCard(Map<String, String> opportunity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.incomeGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.incomeGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(opportunity['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(opportunity['description']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  opportunity['value']!,
                  style: const TextStyle(fontSize: 12, color: AppColors.incomeGreen, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _handleOpportunity(opportunity),
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTrend() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Health Score Trend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        return Text(months[value.toInt() % months.length], style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 680),
                      FlSpot(1, 695),
                      FlSpot(2, 710),
                      FlSpot(3, 725),
                      FlSpot(4, 738),
                      FlSpot(5, 742),
                    ],
                    isCurved: true,
                    color: AppColors.incomeGreen,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.incomeGreen.withOpacity(0.1),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPlan() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalized Action Plan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildActionItem('1. Build Emergency Fund', 'Save \$200 more monthly', Icons.savings, false),
          _buildActionItem('2. Reduce Food Spending', 'Set \$500 monthly limit', Icons.restaurant, false),
          _buildActionItem('3. Increase Investments', 'Add \$300 to portfolio', Icons.trending_up, true),
          _buildActionItem('4. Optimize Bills', 'Enable auto-negotiation', Icons.receipt_long, false),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Start Action Plan',
            gradient: AppColors.incomeGradient,
            onPressed: () => _startActionPlan(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String description, IconData icon, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: completed ? AppColors.incomeGreen.withOpacity(0.1) : AppColors.primaryIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              completed ? Icons.check : icon,
              color: completed ? AppColors.incomeGreen : AppColors.primaryIndigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: completed ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (!completed)
            TextButton(
              onPressed: () => _completeAction(title),
              child: const Text('Do it', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 800) return Colors.green;
    if (score >= 650) return Colors.blue;
    if (score >= 500) return Colors.orange;
    return Colors.red;
  }

  String _getScoreGrade(double score) {
    if (score >= 800) return 'EXCELLENT';
    if (score >= 650) return 'GOOD';
    if (score >= 500) return 'FAIR';
    return 'POOR';
  }

  String _getScoreDescription(double score) {
    if (score >= 800) return 'Outstanding financial health! Keep it up!';
    if (score >= 650) return 'Good financial health with room to grow';
    if (score >= 500) return 'Fair health, focus on improvement areas';
    return 'Needs attention - follow the action plan';
  }

  Color _getCategoryColor(double value) {
    if (value >= 0.8) return AppColors.incomeGreen;
    if (value >= 0.6) return Colors.blue;
    if (value >= 0.4) return Colors.orange;
    return AppColors.expenseRed;
  }

  Future<void> _refreshHealthScore() async {
    setState(() {
      _isLoading = true;
    });
    await _loadHealthData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Financial health score updated!')),
    );
  }

  void _handleRiskAction(Map<String, String> risk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(risk['title']!),
        content: Text('Would you like AI assistance to ${risk['action']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enableAIAssistance(risk);
            },
            child: const Text('Yes, Help Me'),
          ),
        ],
      ),
    );
  }

  void _handleOpportunity(Map<String, String> opportunity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(opportunity['title']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(opportunity['description']!),
            const SizedBox(height: 8),
            Text(
              'Potential benefit: ${opportunity['value']}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.incomeGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exploreOpportunity(opportunity);
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }

  void _startActionPlan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Start Your Action Plan'),
        content: const Text('We\'ll guide you through each step and track your progress. Ready to improve your financial health?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Action plan activated! 🎯')),
              );
            },
            child: const Text('Let\'s Go!'),
          ),
        ],
      ),
    );
  }

  void _completeAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action marked as complete! 🎉')),
    );
  }

  void _enableAIAssistance(Map<String, String> risk) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI assistant activated for this risk! 🤖')),
    );
  }

  void _exploreOpportunity(Map<String, String> opportunity) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exploring opportunity details... 💡')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}