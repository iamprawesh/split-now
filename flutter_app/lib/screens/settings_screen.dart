import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/currency.dart';
import '../providers/settings_provider.dart';
import '../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionHeader('Appearance', isDark),
          Container(
            decoration: BoxDecoration(
              color: isDark ? cardBgDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? borderDark : borderLight, width: 0.5),
            ),
            child: Column(
              children: [
                _themeOption(context, ref, settings, notifier,
                    ThemeMode.light, Icons.light_mode_outlined, 'Light'),
                _divider(isDark),
                _themeOption(context, ref, settings, notifier,
                    ThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
                _divider(isDark),
                _themeOption(context, ref, settings, notifier,
                    ThemeMode.system, Icons.settings_brightness_outlined, 'System'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _sectionHeader('Currency', isDark),
          Container(
            decoration: BoxDecoration(
              color: isDark ? cardBgDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? borderDark : borderLight, width: 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Currency>(
                value: settings.currency,
                isExpanded: true,
                icon: Icon(Icons.expand_more,
                    color: isDark ? textSecondaryDark : textSecondary),
                items: Currency.all.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              c.symbol,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${c.name} (${c.code})',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? textPrimaryDark : textPrimary,
                                ),
                              ),
                              Text(
                                '${c.symbol}1,234.56',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? textSecondaryDark : textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Currency? c) {
                  if (c != null) notifier.setCurrency(c);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? textSecondaryDark : textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    SettingsNotifier notifier,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = settings.themeMode == mode;
    return InkWell(
      onTap: () => notifier.setThemeMode(mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20,
                color: isDark ? textSecondaryDark : textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? textPrimaryDark : textPrimary,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? accent : (isDark ? borderDark : borderLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: isDark ? borderDark : borderLight,
      indent: 16,
      endIndent: 16,
    );
  }
}
