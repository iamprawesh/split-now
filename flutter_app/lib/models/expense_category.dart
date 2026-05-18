import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String defaultTitle;
  final List<String> keywords;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.defaultTitle,
    this.keywords = const [],
  });

  static const List<ExpenseCategory> all = [
    ExpenseCategory(
      id: 'food',
      name: 'Food & Dining',
      icon: Icons.restaurant,
      color: Color(0xFFFF6B6B),
      defaultTitle: 'Food & Dining',
      keywords: ['food', 'dinner', 'lunch', 'breakfast', 'pizza', 'burger', 'restaurant', 'cafe', 'meal', 'snack', 'noodle', 'pasta', 'steak', 'salad'],
    ),
    ExpenseCategory(
      id: 'groceries',
      name: 'Groceries',
      icon: Icons.shopping_cart,
      color: Color(0xFF4ECDC4),
      defaultTitle: 'Groceries',
      keywords: ['grocery', 'supermarket', 'milk', 'bread', 'vegetables', 'fruits', 'market', 'rice', 'flour', 'eggs', 'butter', 'cheese'],
    ),
    ExpenseCategory(
      id: 'transportation',
      name: 'Transportation',
      icon: Icons.directions_car,
      color: Color(0xFF45B7D1),
      defaultTitle: 'Transportation',
      keywords: ['taxi', 'uber', 'gas', 'fuel', 'parking', 'bus', 'cab', 'metro', 'train', 'auto', 'ride', 'toll', 'fare'],
    ),
    ExpenseCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.theater_comedy,
      color: Color(0xFF96CEB4),
      defaultTitle: 'Entertainment',
      keywords: ['movie', 'cinema', 'game', 'netflix', 'show', 'concert', 'party', 'fun', 'theater', 'ticket', 'arcade', 'bowling'],
    ),
    ExpenseCategory(
      id: 'utilities',
      name: 'Utilities',
      icon: Icons.bolt,
      color: Color(0xFFFFD93D),
      defaultTitle: 'Utilities',
      keywords: ['electric', 'water', 'bill', 'electricity', 'power', 'gas', 'sewage', 'utility'],
    ),
    ExpenseCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Color(0xFFDDA0DD),
      defaultTitle: 'Shopping',
      keywords: ['clothes', 'shoes', 'dress', 'shirt', 'amazon', 'electronics', 'outfit', 'jacket', 'pants', 'store', 'mall', 'purchase'],
    ),
    ExpenseCategory(
      id: 'rent',
      name: 'Rent/Housing',
      icon: Icons.home,
      color: Color(0xFF6C5CE7),
      defaultTitle: 'Rent',
      keywords: ['rent', 'housing', 'mortgage', 'apartment', 'flat', 'landlord', 'lease'],
    ),
    ExpenseCategory(
      id: 'travel',
      name: 'Travel',
      icon: Icons.flight,
      color: Color(0xFF00B894),
      defaultTitle: 'Travel',
      keywords: ['flight', 'hotel', 'trip', 'travel', 'airbnb', 'vacation', 'tour', 'booking', 'airline', 'cruise'],
    ),
    ExpenseCategory(
      id: 'medical',
      name: 'Medical',
      icon: Icons.local_hospital,
      color: Color(0xFFE17055),
      defaultTitle: 'Medical',
      keywords: ['doctor', 'hospital', 'pharmacy', 'medicine', 'health', 'clinic', 'surgery', 'lab', 'test', 'prescription'],
    ),
    ExpenseCategory(
      id: 'gifts',
      name: 'Gifts',
      icon: Icons.card_giftcard,
      color: Color(0xFFFD79A8),
      defaultTitle: 'Gift',
      keywords: ['gift', 'birthday', 'present', 'anniversary', 'wedding'],
    ),
    ExpenseCategory(
      id: 'drinks',
      name: 'Drinks/Nightlife',
      icon: Icons.local_bar,
      color: Color(0xFF636E72),
      defaultTitle: 'Drinks',
      keywords: ['tea', 'coffee', 'bar', 'club', 'beer', 'drink', 'alcohol', 'latte', 'chai', 'juice', 'milkshake', 'wine', 'cocktail', 'pub'],
    ),
    ExpenseCategory(
      id: 'education',
      name: 'Education',
      icon: Icons.school,
      color: Color(0xFF0984E3),
      defaultTitle: 'Education',
      keywords: ['course', 'book', 'tuition', 'school', 'class', 'study', 'lesson', 'exam', 'tuition', 'college', 'university'],
    ),
    ExpenseCategory(
      id: 'household',
      name: 'Household',
      icon: Icons.cleaning_services,
      color: Color(0xFFB2BEC3),
      defaultTitle: 'Household',
      keywords: ['cleaning', 'soap', 'detergent', 'repair', 'broom', 'tissue', 'trash', 'plumbing', 'furniture'],
    ),
    ExpenseCategory(
      id: 'subscriptions',
      name: 'Subscriptions',
      icon: Icons.subscriptions,
      color: Color(0xFF74B9FF),
      defaultTitle: 'Subscription',
      keywords: ['subscription', 'monthly', 'membership', 'premium', 'spotify', 'renewal'],
    ),
    ExpenseCategory(
      id: 'pets',
      name: 'Pets',
      icon: Icons.pets,
      color: Color(0xFFA29BFE),
      defaultTitle: 'Pets',
      keywords: ['pet', 'vet', 'dog', 'cat', 'animal', 'food', 'grooming'],
    ),
    ExpenseCategory(
      id: 'fitness',
      name: 'Fitness/Sports',
      icon: Icons.fitness_center,
      color: Color(0xFFFF7675),
      defaultTitle: 'Fitness',
      keywords: ['gym', 'fitness', 'sport', 'workout', 'exercise', 'yoga', 'weights', 'trainer'],
    ),
    ExpenseCategory(
      id: 'insurance',
      name: 'Insurance',
      icon: Icons.shield,
      color: Color(0xFF2D3436),
      defaultTitle: 'Insurance',
      keywords: ['insurance', 'policy', 'premium', 'coverage', 'claim'],
    ),
    ExpenseCategory(
      id: 'savings',
      name: 'Savings',
      icon: Icons.savings,
      color: Color(0xFF00CEC9),
      defaultTitle: 'Savings',
      keywords: ['savings', 'deposit', 'investment', 'bank', 'account', 'transfer'],
    ),
    ExpenseCategory(
      id: 'childcare',
      name: 'Childcare',
      icon: Icons.child_care,
      color: Color(0xFFFDCB6E),
      defaultTitle: 'Childcare',
      keywords: ['baby', 'childcare', 'daycare', 'kid', 'child', 'nanny', 'school'],
    ),
    ExpenseCategory(
      id: 'taxes',
      name: 'Taxes/Fees',
      icon: Icons.receipt_long,
      color: Color(0xFFDFE6E9),
      defaultTitle: 'Taxes',
      keywords: ['tax', 'fee', 'fine', 'penalty', 'vat', 'duties', 'levy'],
    ),
    ExpenseCategory(
      id: 'phone_internet',
      name: 'Phone/Internet',
      icon: Icons.smartphone,
      color: Color(0xFF55EFC4),
      defaultTitle: 'Phone/Internet',
      keywords: ['phone', 'sim', 'data', 'mobile', 'recharge', 'internet', 'wifi', 'broadband'],
    ),
    ExpenseCategory(
      id: 'beauty',
      name: 'Beauty/Self Care',
      icon: Icons.content_cut,
      color: Color(0xFFFAB1A0),
      defaultTitle: 'Beauty',
      keywords: ['salon', 'haircut', 'spa', 'beauty', 'skincare', 'makeup', 'cosmetics', 'nails'],
    ),
    ExpenseCategory(
      id: 'charity',
      name: 'Charity/Donations',
      icon: Icons.favorite,
      color: Color(0xFF81ECEC),
      defaultTitle: 'Charity',
      keywords: ['charity', 'donation', 'donate', 'fund', 'help', 'relief'],
    ),
    ExpenseCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFFB2BEC3),
      defaultTitle: 'Other',
      keywords: [],
    ),
  ];

  static ExpenseCategory fromId(String? id) {
    if (id == null || id.isEmpty) return all.last;
    return all.firstWhere(
      (c) => c.id == id,
      orElse: () => all.last,
    );
  }

  static ExpenseCategory detectCategory(String title) {
    if (title.trim().isEmpty) return all.last;

    final lowerTitle = title.toLowerCase();
    final words = lowerTitle.split(RegExp(r'\s+'));

    for (final category in all) {
      if (category.keywords.isEmpty) continue;
      for (final keyword in category.keywords) {
        if (lowerTitle.contains(keyword)) return category;
        for (final word in words) {
          if (word.contains(keyword) || keyword.contains(word)) {
            if (word.length > 2) return category;
          }
        }
      }
    }

    return all.last;
  }
}
