import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

const Color accent = Color(0xFF5B5FEF);
const Color surfaceBg = Color(0xFFF8F9FA);
const Color cardBg = Color(0xFFFFFFFF);
const Color textPrimary = Color(0xFF1A1A2E);
const Color textSecondary = Color(0xFF6B7280);
const Color borderLight = Color(0xFFE5E7EB);
const Color greenAccent = Color(0xFF10B981);
const Color redAccent = Color(0xFFEF4444);

const Color surfaceBgDark = Color(0xFF0F0F1A);
const Color cardBgDark = Color(0xFF1A1A2E);
const Color textPrimaryDark = Color(0xFFE8E8F0);
const Color textSecondaryDark = Color(0xFF9CA3AF);
const Color borderDark = Color(0xFF2D2D3A);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: SplitwiseApp()));
}

class SplitwiseApp extends ConsumerStatefulWidget {
  const SplitwiseApp({super.key});

  @override
  ConsumerState<SplitwiseApp> createState() => _SplitwiseAppState();
}

class _SplitwiseAppState extends ConsumerState<SplitwiseApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(apiServiceProvider).init();
      ref.read(authProvider.notifier).checkAuth();
      ref.read(settingsProvider.notifier).loadSettings();
      ref.read(notificationServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SplitEase',
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: accent,
          onPrimary: Colors.white,
          surface: surfaceBg,
          onSurface: textPrimary,
          secondary: accent.withValues(alpha: 0.1),
          outline: borderLight,
        ),
        scaffoldBackgroundColor: surfaceBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: borderLight, width: 0.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: borderLight),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceBg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: accent.withValues(alpha: 0.1),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: accent);
            }
            return const IconThemeData(color: textSecondary);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: accent,
          unselectedLabelColor: textSecondary,
          indicatorColor: accent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        dividerTheme: const DividerThemeData(
          color: borderLight,
          thickness: 0.5,
          space: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: CircleBorder(),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: accent,
          onPrimary: Colors.white,
          surface: surfaceBgDark,
          onSurface: textPrimaryDark,
          secondary: accent.withValues(alpha: 0.15),
          outline: borderDark,
        ),
        scaffoldBackgroundColor: surfaceBgDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: cardBgDark,
          foregroundColor: textPrimaryDark,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimaryDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardBgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: borderDark, width: 0.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimaryDark,
            side: const BorderSide(color: borderDark),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceBgDark,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondaryDark, fontSize: 14),
          hintStyle: TextStyle(color: textSecondaryDark.withValues(alpha: 0.5)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: cardBgDark,
          indicatorColor: accent.withValues(alpha: 0.15),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: accent);
            }
            return const IconThemeData(color: textSecondaryDark);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: textSecondaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: accent,
          unselectedLabelColor: textSecondaryDark,
          indicatorColor: accent,
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        dividerTheme: const DividerThemeData(
          color: borderDark,
          thickness: 0.5,
          space: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: CircleBorder(),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
