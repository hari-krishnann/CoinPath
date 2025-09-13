// screens/smart_investment_page.dart
// 🚀 REVOLUTIONARY FEATURE 1: AI-Powered Smart Investing Dashboard
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../services/firestore_service.dart';
import '../models/transaction.dart';

class SmartInvestmentPage extends StatefulWidget {
  const SmartInvestmentPage({Key? key}) : super(key: key);

  @override
  _SmartInvestmentPageState createState() => _SmartInvestmentPageState();
}

class _SmartInvestmentPageState extends State<SmartInvestmentPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  SmartInvestmentModel? _portfolio;
  bool _isLoading = true;
  double _totalRoundups = 0.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _loadInvestmentData();
    _controller.forward();
  }

  Future<void> _loadInvestmentData() async {
    try {
      final portfolio = await FirestoreService().getInvestmentPortfolio('default_user');
      setState(() {
        _portfolio = portfolio;
        _totalRoundups = 234.56; // Simulated data
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
        title: const Text('Smart Investing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showInvestmentSettings(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPortfolioOverview(),
                      const SizedBox(height: 16),
                      _buildSpareChangeCard(),
                      const SizedBox(height: 16),
                      _buildPerformanceChart(),
                      const SizedBox(height: 16),
                      _buildAIRecommendations(),
                      const SizedBox(height: 16),
                      _buildRiskAssessment(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPortfolioOverview() {
    return ModernCard(
      gradient: AppColors.incomeGradient,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Portfolio Value',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '\$${_portfolio?.currentValue.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Invested',
                  '\$${_portfolio?.totalInvested.toStringAsFixed(2) ?? '0.00'}',
                  Icons.account_balance_wallet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Total Returns',
                  '\$${_portfolio?.totalReturns.toStringAsFixed(2) ?? '0.00'}',
                  Icons.show_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpareChangeCard() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.incomeGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.savings, color: AppColors.incomeGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spare Change Investing',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Auto-invested from roundups',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: true,
                onChanged: (value) {},
                activeColor: AppColors.incomeGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.incomeGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.incomeGreen.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('This Month\'s Roundups'),
                      Text(
                        '\$$_totalRoundups',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.incomeGreen,
                        ),
                      ),
                      const Text('From 47 transactions', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.incomeGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.incomeGreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio Performance',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 0),
                      FlSpot(1, 150),
                      FlSpot(2, 280),
                      FlSpot(3, 320),
                      FlSpot(4, 450),
                      FlSpot(5, 520),
                    ],
                    isCurved: true,
                    gradient: AppColors.incomeGradient,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.incomeGreen.withOpacity(0.3),
                          AppColors.incomeGreen.withOpacity(0.0),
                        ],
                      ),
                    ),
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPerformanceMetric('1D', '+2.4%', AppColors.incomeGreen),
              _buildPerformanceMetric('1W', '+5.7%', AppColors.incomeGreen),
              _buildPerformanceMetric('1M', '+12.3%', AppColors.incomeGreen),
              _buildPerformanceMetric('YTD', '+18.9%', AppColors.incomeGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String period, String performance, Color color) {
    return Column(
      children: [
        Text(period, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          performance,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildAIRecommendations() {
    final recommendations = _portfolio?.aiRecommendations ?? [
      'Consider increasing your crypto allocation by 5%',
      'Market conditions favor tech stocks this quarter',
      'Your risk tolerance allows for growth investments',
    ];

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primaryIndigo),
              const SizedBox(width: 12),
              const Text(
                'AI Investment Recommendations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryIndigo,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(rec)),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 16),
                  onPressed: () => _showRecommendationDetails(rec),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRiskAssessment() {
    final riskScore = _portfolio?.riskScore ?? 5.0;
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Assessment',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Risk Score: ${riskScore.toStringAsFixed(1)}/10'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: riskScore / 10,
                      backgroundColor: AppColors.textMuted.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        riskScore > 7 ? AppColors.expenseRed :
                        riskScore > 4 ? Colors.orange : AppColors.incomeGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      riskScore > 7 ? 'High Risk - High Reward' :
                      riskScore > 4 ? 'Moderate Risk' : 'Conservative',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _showRiskDetails(),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GradientButton(
                text: 'Manual Invest',
                gradient: AppColors.incomeGradient,
                onPressed: () => _showManualInvestDialog(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showPortfolioDetails(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryIndigo,
                  side: const BorderSide(color: AppColors.primaryIndigo),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showInvestmentEducation(),
          icon: const Icon(Icons.school, size: 16),
          label: const Text('Learn About Investing'),
        ),
      ],
    );
  }

  void _showInvestmentSettings() {
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
            const Text('Investment Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildSettingTile('Auto-invest spare change', true),
            _buildSettingTile('Rebalance portfolio monthly', true),
            _buildSettingTile('Reinvest dividends', true),
            _buildSettingTile('Send performance notifications', false),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Save Settings',
              gradient: AppColors.incomeGradient,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(String title, bool value) {
    return ListTile(
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {},
        activeColor: AppColors.incomeGreen,
      ),
    );
  }

  void _showManualInvestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Manual Investment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Amount to invest',
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text('Recommended allocation based on your risk profile:'),
            const SizedBox(height: 8),
            const Text('• 70% Stocks (ETFs)\n• 20% Bonds\n• 10% Cryptocurrency'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInvestmentSuccess();
            },
            child: const Text('Invest'),
          ),
        ],
      ),
    );
  }

  void _showInvestmentSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Investment placed successfully! 🎉'),
        backgroundColor: AppColors.incomeGreen,
      ),
    );
  }

  void _showRecommendationDetails(String recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('AI Recommendation'),
        content: Text('$recommendation\n\nThis recommendation is based on your spending patterns, risk tolerance, and current market conditions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showRiskDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Risk Assessment Details'),
        content: const Text('Your risk score is calculated based on your income stability, savings rate, and investment preferences. A moderate risk profile balances growth potential with safety.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update Risk Profile'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPortfolioDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PortfolioDetailsPage(),
      ),
    );
  }

  void _showInvestmentEducation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Investment Education', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: const [
                    Text('🎓 Investment Basics'),
                    SizedBox(height: 8),
                    Text('Learn about different investment types, risk management, and building a diversified portfolio.'),
                    SizedBox(height: 16),
                    Text('📈 Market Analysis'),
                    SizedBox(height: 8),
                    Text('Understand market trends and how they affect your investments.'),
                    SizedBox(height: 16),
                    Text('💰 Compound Interest'),
                    SizedBox(height: 8),
                    Text('Discover how your money can grow exponentially over time.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Supporting page for detailed portfolio view
class PortfolioDetailsPage extends StatelessWidget {
  const PortfolioDetailsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Detailed portfolio breakdown coming soon!'),
      ),
    );
  }
}