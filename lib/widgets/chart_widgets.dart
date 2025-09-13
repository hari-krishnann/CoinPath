// widgets/chart_widgets.dart
// Chart widgets using fl_chart for reports
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../models/transaction.dart';
import '../theme.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  final List<double> incomeData;
  final List<double> expenseData;
  final List<String> months;

  const IncomeExpenseBarChart({Key? key, required this.incomeData, required this.expenseData, required this.months}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(months.length, (i) => BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: incomeData[i], color: Colors.green),
            BarChartRodData(toY: expenseData[i], color: Colors.red),
          ])),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
              if (value.toInt() < months.length) {
                return Text(months[value.toInt()], style: TextStyle(fontSize: 10));
              }
              return Text('');
            })),
          ),
        ),
      ),
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const CategoryPieChart({Key? key, required this.categoryData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sections = categoryData.entries.map((e) => PieChartSectionData(
      value: e.value,
      title: e.key,
      color: Colors.primaries[categoryData.keys.toList().indexOf(e.key) % Colors.primaries.length],
      radius: 40,
      titleStyle: TextStyle(fontSize: 12, color: Colors.white),
    )).toList();
    return SizedBox(
      height: 200,
      child: PieChart(PieChartData(sections: sections)),
    );
  }
}

// Modern Sankey Diagram for Income Flow Visualization
class IncomeSankeyDiagram extends StatelessWidget {
  final List<TransactionModel> transactions;
  final double height;

  const IncomeSankeyDiagram({
    Key? key,
    required this.transactions,
    this.height = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sankeyData = _processSankeyData();
    
    if (sankeyData['totalIncome'] == 0) {
      return _buildEmptyState();
    }

    return Container(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: SankeyDiagramPainter(
          sankeyData: sankeyData,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceBg.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textMuted.withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
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
              'Add income transactions to see flow visualization',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _processSankeyData() {
    // Income sources (left side)
    double cashIncome = 0;
    double chequeIncome = 0;
    
    // Expense categories (right side)
    Map<String, Map<String, double>> categoryFlows = {
      'Food': {'cash': 0, 'cheque': 0},
      'Rent': {'cash': 0, 'cheque': 0},
      'Shopping': {'cash': 0, 'cheque': 0},
      'Transport': {'cash': 0, 'cheque': 0},
      'Miscellaneous': {'cash': 0, 'cheque': 0},
    };

    // Process transactions
    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        if (transaction.paymentMethod == 'cash') {
          cashIncome += transaction.amount;
        } else {
          chequeIncome += transaction.amount;
        }
      } else if (transaction.type == 'expense') {
        final category = _normalizeCategory(transaction.category);
        if (categoryFlows.containsKey(category)) {
          if (transaction.paymentMethod == 'cash') {
            categoryFlows[category]!['cash'] = 
                (categoryFlows[category]!['cash'] ?? 0) + transaction.amount;
          } else {
            categoryFlows[category]!['cheque'] = 
                (categoryFlows[category]!['cheque'] ?? 0) + transaction.amount;
          }
        }
      }
    }

    return {
      'cashIncome': cashIncome,
      'chequeIncome': chequeIncome,
      'totalIncome': cashIncome + chequeIncome,
      'categoryFlows': categoryFlows,
    };
  }

  String _normalizeCategory(String category) {
    // Map various category names to our standard categories
    final categoryMap = {
      'food': 'Food',
      'groceries': 'Food',
      'dining': 'Food',
      'restaurants': 'Food',
      'rent': 'Rent',
      'housing': 'Rent',
      'utilities': 'Rent',
      'shopping': 'Shopping',
      'retail': 'Shopping',
      'clothing': 'Shopping',
      'transport': 'Transport',
      'transportation': 'Transport',
      'gas': 'Transport',
      'fuel': 'Transport',
      'uber': 'Transport',
      'taxi': 'Transport',
      'miscellaneous': 'Miscellaneous',
      'misc': 'Miscellaneous',
      'other': 'Miscellaneous',
      'entertainment': 'Miscellaneous',
      'health': 'Miscellaneous',
      'medical': 'Miscellaneous',
    };

    final normalizedKey = category.toLowerCase().trim();
    return categoryMap[normalizedKey] ?? 'Miscellaneous';
  }
}

class SankeyDiagramPainter extends CustomPainter {
  final Map<String, dynamic> sankeyData;

  SankeyDiagramPainter({required this.sankeyData});

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = 40;
    final double nodeWidth = 15;
    final double nodeSpacing = 30;
    
    // Calculate positions
    final double leftX = padding;
    final double rightX = size.width - padding - nodeWidth;
    final double centerY = size.height / 2;

    // Income source positions (left side)
    final double cashIncomeHeight = _calculateNodeHeight(sankeyData['cashIncome'], sankeyData['totalIncome'], size.height - 2 * padding);
    final double chequeIncomeHeight = _calculateNodeHeight(sankeyData['chequeIncome'], sankeyData['totalIncome'], size.height - 2 * padding);
    
    double currentY = padding;
    final Rect cashIncomeRect = Rect.fromLTWH(leftX, currentY, nodeWidth, cashIncomeHeight);
    currentY += cashIncomeHeight + nodeSpacing;
    final Rect chequeIncomeRect = Rect.fromLTWH(leftX, currentY, nodeWidth, chequeIncomeHeight);

    // Category positions (right side)
    final Map<String, Rect> categoryRects = {};
    final Map<String, Map<String, double>> categoryFlows = sankeyData['categoryFlows'];
    
    currentY = padding;
    for (final category in categoryFlows.keys) {
      final totalCategoryAmount = (categoryFlows[category]!['cash'] ?? 0) + (categoryFlows[category]!['cheque'] ?? 0);
      final categoryHeight = _calculateNodeHeight(totalCategoryAmount, sankeyData['totalIncome'], size.height - 2 * padding);
      
      if (categoryHeight > 0) {
        categoryRects[category] = Rect.fromLTWH(rightX, currentY, nodeWidth, categoryHeight);
        currentY += categoryHeight + nodeSpacing;
      }
    }

    // Draw flows (connections)
    _drawFlows(canvas, sankeyData, cashIncomeRect, chequeIncomeRect, categoryRects);

    // Draw nodes
    _drawIncomeNodes(canvas, cashIncomeRect, chequeIncomeRect, sankeyData);
    _drawCategoryNodes(canvas, categoryRects, categoryFlows);

    // Draw labels
    _drawLabels(canvas, cashIncomeRect, chequeIncomeRect, categoryRects, sankeyData);
  }

  double _calculateNodeHeight(double value, double total, double maxHeight) {
    if (total == 0) return 0;
    return math.max(8, (value / total) * maxHeight);
  }

  void _drawFlows(Canvas canvas, Map<String, dynamic> data, Rect cashRect, Rect chequeRect, Map<String, Rect> categoryRects) {
    final Map<String, Map<String, double>> categoryFlows = data['categoryFlows'];

    for (final category in categoryFlows.keys) {
      if (!categoryRects.containsKey(category)) continue;
      
      final categoryRect = categoryRects[category]!;
      final cashFlow = categoryFlows[category]!['cash'] ?? 0;
      final chequeFlow = categoryFlows[category]!['cheque'] ?? 0;

      // Draw cash flows (red)
      if (cashFlow > 0) {
        _drawFlow(
          canvas,
          cashRect,
          categoryRect,
          cashFlow,
          data['totalIncome'],
          AppColors.cashRed.withOpacity(0.6),
        );
      }

      // Draw cheque flows (blue)
      if (chequeFlow > 0) {
        _drawFlow(
          canvas,
          chequeRect,
          categoryRect,
          chequeFlow,
          data['totalIncome'],
          AppColors.chequeBlue.withOpacity(0.6),
        );
      }
    }
  }

  void _drawFlow(Canvas canvas, Rect source, Rect target, double amount, double totalAmount, Color color) {
    final sourceCenter = Offset(source.right, source.center.dy);
    final targetCenter = Offset(target.left, target.center.dy);
    
    final controlPoint1 = Offset(
      sourceCenter.dx + (targetCenter.dx - sourceCenter.dx) * 0.5,
      sourceCenter.dy,
    );
    
    final controlPoint2 = Offset(
      sourceCenter.dx + (targetCenter.dx - sourceCenter.dx) * 0.5,
      targetCenter.dy,
    );

    final path = Path()
      ..moveTo(sourceCenter.dx, sourceCenter.dy)
      ..cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        targetCenter.dx,
        targetCenter.dy,
      );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, (amount / totalAmount) * 30)
      ..color = color
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  void _drawIncomeNodes(Canvas canvas, Rect cashRect, Rect chequeRect, Map<String, dynamic> data) {
    // Cash income node
    final cashPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [AppColors.cashRed, Color(0xFFFF6B6B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(cashRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(cashRect, const Radius.circular(8)),
      cashPaint,
    );

    // Cheque income node
    final chequePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [AppColors.chequeBlue, Color(0xFF4F9EF8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chequeRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(chequeRect, const Radius.circular(8)),
      chequePaint,
    );
  }

  void _drawCategoryNodes(Canvas canvas, Map<String, Rect> categoryRects, Map<String, Map<String, double>> categoryFlows) {
    final categoryColors = {
      'Food': const Color(0xFF10B981),
      'Rent': const Color(0xFF8B5CF6),
      'Shopping': const Color(0xFFEC4899),
      'Transport': const Color(0xFFF59E0B),
      'Miscellaneous': const Color(0xFF6B7280),
    };

    for (final category in categoryRects.keys) {
      final rect = categoryRects[category]!;
      final color = categoryColors[category] ?? AppColors.textMuted;
      
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Rect cashRect, Rect chequeRect, Map<String, Rect> categoryRects, Map<String, dynamic> data) {
    // Income labels (left side)
    _drawLabel(canvas, 'Cash Income', Offset(cashRect.left - 10, cashRect.center.dy), true);
    _drawLabel(canvas, 'Cheque Income', Offset(chequeRect.left - 10, chequeRect.center.dy), true);

    // Category labels (right side)
    for (final category in categoryRects.keys) {
      final rect = categoryRects[category]!;
      _drawLabel(canvas, category, Offset(rect.right + 10, rect.center.dy), false);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset position, bool alignRight) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final offset = alignRight
        ? Offset(position.dx - textPainter.width, position.dy - textPainter.height / 2)
        : Offset(position.dx, position.dy - textPainter.height / 2);
    
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Add support for creating home and lock screen widgets
// Implement widgets to display quick updates on income and expenses

class HomeScreenWidget extends StatelessWidget {
  final double income;
  final double expenses;

  const HomeScreenWidget({Key? key, required this.income, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Income: \$${income.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: Colors.green)),
        Text('Expenses: \$${expenses.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: Colors.red)),
      ],
    );
  }
}

class LockScreenWidget extends StatelessWidget {
  final double income;
  final double expenses;

  const LockScreenWidget({Key? key, required this.income, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Income: \$${income.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: Colors.green)),
        Text('Expenses: \$${expenses.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: Colors.red)),
      ],
    );
  }
}