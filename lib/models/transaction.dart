// models/transaction.dart
// Model for a transaction (income or expense) - Updated for compatibility
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final String paymentMethod; // 'cash', 'cheque', 'amex', 'bofa', 'discover', 'apple_card', 'zolve'
  final bool isRecurring;
  
  // Enhanced fields for your workflow
  final String? accountType; // 'income_source', 'credit_card', 'payment'
  final String? linkedTransactionId; // For linking credit card payments to spending
  final double? outstandingBalance; // For credit cards
  final DateTime? dueDate; // For credit card payments
  final bool isPaid; // For tracking payment status
  
  // New fields for revolutionary features
  final double? spareChangeRoundup; // For smart investing
  final int? creditScoreImpact; // Predicted impact on credit score
  final String? merchantId; // For bill negotiation tracking
  final List<String>? sharedWithUsers; // For social expense splitting
  final double? financialHealthScore; // Impact on overall financial health
  final Map<String, dynamic>? aiInsights; // AI-generated insights

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    required this.paymentMethod,
    this.isRecurring = false, // Made optional with default value
    this.accountType,
    this.linkedTransactionId,
    this.outstandingBalance,
    this.dueDate,
    this.isPaid = false,
    this.spareChangeRoundup,
    this.creditScoreImpact,
    this.merchantId,
    this.sharedWithUsers,
    this.financialHealthScore,
    this.aiInsights,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      type: data['type'],
      amount: (data['amount'] as num).toDouble(),
      category: data['category'],
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
      paymentMethod: data['paymentMethod'] ?? 'cash',
      isRecurring: data['isRecurring'] ?? false,
      accountType: data['accountType'],
      linkedTransactionId: data['linkedTransactionId'],
      outstandingBalance: data['outstandingBalance']?.toDouble(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      isPaid: data['isPaid'] ?? false,
      spareChangeRoundup: data['spareChangeRoundup']?.toDouble(),
      creditScoreImpact: data['creditScoreImpact'],
      merchantId: data['merchantId'],
      sharedWithUsers: data['sharedWithUsers'] != null 
          ? List<String>.from(data['sharedWithUsers']) 
          : null,
      financialHealthScore: data['financialHealthScore']?.toDouble(),
      aiInsights: data['aiInsights'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'category': category,
      'date': date,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'isRecurring': isRecurring,
      'accountType': accountType,
      'linkedTransactionId': linkedTransactionId,
      'outstandingBalance': outstandingBalance,
      'dueDate': dueDate,
      'isPaid': isPaid,
      'spareChangeRoundup': spareChangeRoundup,
      'creditScoreImpact': creditScoreImpact,
      'merchantId': merchantId,
      'sharedWithUsers': sharedWithUsers,
      'financialHealthScore': financialHealthScore,
      'aiInsights': aiInsights,
    };
  }
}

// NEW: Smart Investment Model
class SmartInvestmentModel {
  final String id;
  final double totalInvested;
  final double currentValue;
  final double totalReturns;
  final List<InvestmentTransaction> transactions;
  final Map<String, double> portfolioAllocation;
  final double riskScore;
  final List<String> aiRecommendations;

  SmartInvestmentModel({
    required this.id,
    required this.totalInvested,
    required this.currentValue,
    required this.totalReturns,
    required this.transactions,
    required this.portfolioAllocation,
    required this.riskScore,
    required this.aiRecommendations,
  });
}

class InvestmentTransaction {
  final String id;
  final double amount;
  final String type; // 'roundup', 'manual', 'dividend_reinvest'
  final DateTime date;
  final String fundType; // 'etf', 'stocks', 'bonds', 'crypto'
  final double? sharePrice;

  InvestmentTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.fundType,
    this.sharePrice,
  });
}

// NEW: Credit Score Model
class CreditScoreModel {
  final String id;
  final int currentScore;
  final int previousScore;
  final DateTime lastUpdated;
  final List<CreditFactor> factors;
  final List<String> improvementTips;
  final double utilization;
  final int paymentHistory;
  final Map<String, dynamic> predictedChanges;

  CreditScoreModel({
    required this.id,
    required this.currentScore,
    required this.previousScore,
    required this.lastUpdated,
    required this.factors,
    required this.improvementTips,
    required this.utilization,
    required this.paymentHistory,
    required this.predictedChanges,
  });
}

class CreditFactor {
  final String category;
  final int impact; // -100 to +100
  final String description;
  final List<String> actionItems;

  CreditFactor({
    required this.category,
    required this.impact,
    required this.description,
    required this.actionItems,
  });
}

// NEW: Bill Optimization Model
class BillOptimizationModel {
  final String id;
  final String billType; // 'utility', 'subscription', 'insurance', etc.
  final String merchantName;
  final double currentAmount;
  final double suggestedAmount;
  final double potentialSavings;
  final DateTime nextNegotiationDate;
  final List<String> negotiationTactics;
  final bool autoNegotiationEnabled;
  final String status; // 'pending', 'negotiating', 'success', 'failed'

  BillOptimizationModel({
    required this.id,
    required this.billType,
    required this.merchantName,
    required this.currentAmount,
    required this.suggestedAmount,
    required this.potentialSavings,
    required this.nextNegotiationDate,
    required this.negotiationTactics,
    required this.autoNegotiationEnabled,
    required this.status,
  });
}

// NEW: Social Finance Model
class SocialGroupModel {
  final String id;
  final String name;
  final List<String> memberIds;
  final List<SharedExpense> expenses;
  final Map<String, double> balances; // userId -> balance (+ owes, - is owed)
  final DateTime createdAt;
  final String? description;

  SocialGroupModel({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.expenses,
    required this.balances,
    required this.createdAt,
    this.description,
  });
}

class SharedExpense {
  final String id;
  final String description;
  final double totalAmount;
  final String paidBy;
  final Map<String, double> splits; // userId -> amount they owe
  final DateTime date;
  final String category;
  final bool isSettled;

  SharedExpense({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.paidBy,
    required this.splits,
    required this.date,
    required this.category,
    required this.isSettled,
  });
}

// NEW: Financial Health Predictor Model
class FinancialHealthModel {
  final String id;
  final double currentScore; // 0-1000
  final DateTime lastCalculated;
  final Map<String, double> categoryScores;
  final List<FinancialRisk> risks;
  final List<FinancialOpportunity> opportunities;
  final Map<String, dynamic> predictions; // 1, 3, 6 month predictions

  FinancialHealthModel({
    required this.id,
    required this.currentScore,
    required this.lastCalculated,
    required this.categoryScores,
    required this.risks,
    required this.opportunities,
    required this.predictions,
  });
}

class FinancialRisk {
  final String id;
  final String type;
  final int severity; // 1-10
  final String description;
  final double probability;
  final DateTime predictedDate;
  final List<String> preventionActions;

  FinancialRisk({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.probability,
    required this.predictedDate,
    required this.preventionActions,
  });
}

class FinancialOpportunity {
  final String id;
  final String type;
  final double potentialValue;
  final String description;
  final List<String> actionSteps;
  final DateTime deadline;

  FinancialOpportunity({
    required this.id,
    required this.type,
    required this.potentialValue,
    required this.description,
    required this.actionSteps,
    required this.deadline,
  });
}

// Refine the transaction model to include additional fields if needed
// Ensure compatibility with the updated app features
