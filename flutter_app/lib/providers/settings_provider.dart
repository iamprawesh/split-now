import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Currency currency;

  static const Currency _defaultCurrency = Currency(
    code: 'USD', name: 'US Dollar', symbol: '\$',
  );

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.currency = _defaultCurrency,
  });

  SettingsState copyWith({ThemeMode? themeMode, Currency? currency}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'currency': currency.code,
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      themeMode: ThemeMode.values[json['themeMode'] ?? ThemeMode.system.index],
      currency: Currency.fromCode(json['currency'] ?? 'USD'),
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'app_settings';

  SettingsNotifier() : super(SettingsState());

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyCode = prefs.getString('selected_currency_code');

      Currency savedCurrency;
      if (savedCurrencyCode != null) {
        savedCurrency = Currency.fromCode(savedCurrencyCode);
      } else {
        savedCurrency = const Currency(code: 'USD', name: 'US Dollar', symbol: '\$');
      }

      try {
        final saved = await _storage.read(key: _storageKey);
        if (saved != null) {
          final json = jsonDecode(saved) as Map<String, dynamic>;
          state = SettingsState.fromJson(json);
          if (savedCurrency.code != 'USD') {
            state = state.copyWith(currency: savedCurrency);
          }
          return;
        }
      } catch (_) {}

      state = SettingsState(currency: savedCurrency);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(state.toJson()),
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _persist();
  }

  Future<void> setCurrency(Currency currency) async {
    state = state.copyWith(currency: currency);
    await _persist();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency_code', currency.code);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

final currentCurrencyProvider = Provider<Currency>((ref) {
  return ref.watch(settingsProvider).currency;
});
