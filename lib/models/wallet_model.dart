import 'package:flutter/material.dart';

enum TransactionType { credit, debit }

enum PaymentMethod { mobileMoney, card, bankTransfer, ussd, wallet }

enum TransactionStatus { pending, processing, completed, failed, cancelled, refunded }

class WalletTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final PaymentMethod method;
  final TransactionStatus status;
  final String description;
  final DateTime date;
  final String? reference;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.method,
    required this.status,
    required this.description,
    required this.date,
    this.reference,
  });

  IconData get icon {
    switch (type) {
      case TransactionType.credit:
        return Icons.arrow_downward;
      case TransactionType.debit:
        return Icons.arrow_upward;
    }
  }

  Color get color {
    switch (type) {
      case TransactionType.credit:
        return const Color(0xFF10B981);
      case TransactionType.debit:
        return Colors.red;
    }
  }
}

class Wallet {
  final double balance;
  final List<WalletTransaction> transactions;
  final double totalSpent;
  final double totalReceived;

  Wallet({
    required this.balance,
    required this.transactions,
    required this.totalSpent,
    required this.totalReceived,
  });

  double get avgTransaction {
    if (transactions.isEmpty) return 0;
    return (totalSpent + totalReceived) / transactions.length;
  }
}

// Loyalty models
enum LoyaltyTier { bronze, silver, gold, platinum }

class LoyaltyReward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String category;
  final bool isRedeemed;

  LoyaltyReward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.category,
    this.isRedeemed = false,
  });
}

class LoyaltyInfo {
  final int currentPoints;
  final int totalEarned;
  final LoyaltyTier tier;
  final int pointsToNextTier;
  final List<LoyaltyReward> availableRewards;

  LoyaltyInfo({
    required this.currentPoints,
    required this.totalEarned,
    required this.tier,
    required this.pointsToNextTier,
    required this.availableRewards,
  });

  String get tierName {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 'Bronze';
      case LoyaltyTier.silver:
        return 'Silver';
      case LoyaltyTier.gold:
        return 'Gold';
      case LoyaltyTier.platinum:
        return 'Platinum';
    }
  }

  Color get tierColor {
    switch (tier) {
      case LoyaltyTier.bronze:
        return const Color(0xFFB45309);
      case LoyaltyTier.silver:
        return const Color(0xFF64748B);
      case LoyaltyTier.gold:
        return const Color(0xFFEAB308);
      case LoyaltyTier.platinum:
        return const Color(0xFF7C3AED);
    }
  }

  double get tierProgress {
    final total = currentPoints + pointsToNextTier;
    if (total == 0) return 0;
    return currentPoints / total;
  }
}
