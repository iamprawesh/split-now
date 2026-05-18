import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/country_currency.dart';
import '../main.dart';

class CurrencyOnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const CurrencyOnboardingScreen({super.key, required this.onComplete});

  @override
  State<CurrencyOnboardingScreen> createState() => _CurrencyOnboardingScreenState();
}

class _CurrencyOnboardingScreenState extends State<CurrencyOnboardingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CountryCurrency? _selected;

  List<CountryCurrency> get _filtered {
    if (_searchQuery.isEmpty) return CountryCurrency.all;
    final q = _searchQuery.toLowerCase();
    return CountryCurrency.all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.currency.code.toLowerCase().contains(q) ||
          c.currency.name.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirmSelection() async {
    if (_selected == null) {
      final first = CountryCurrency.all.first;
      _selected = first;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setString('selected_currency_code', _selected!.currency.code);

    if (mounted) widget.onComplete();
  }

  void _selectCountry(CountryCurrency cc) {
    HapticFeedback.lightImpact();
    setState(() => _selected = cc);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEEF0FF),
                Color(0xFFF8F9FA),
                Color(0xFFFFFFFF),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, Color(0xFF7C80F5)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.language_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Choose Your Currency',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Select your country to set the currency for all expenses and balances.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search country or currency...',
                      prefixIcon: const Icon(Icons.search_rounded, color: textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: accent, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final cc = _filtered[i];
                      final isSelected = _selected?.currency.code == cc.currency.code;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          elevation: 0,
                          child: InkWell(
                            onTap: () {
                              _selectCountry(cc);
                              Future.delayed(const Duration(milliseconds: 150), _confirmSelection);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? accent : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    cc.flagEmoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cc.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cc.currency.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textSecondary.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    cc.currency.code,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? accent : textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSelected)
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                                    )
                                  else
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: borderLight, width: 1.5),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_searchQuery.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Tap any country to select and continue',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
