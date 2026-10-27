import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final DatabaseService dbService = DatabaseService();

  runApp(
    MultiProvider(
      providers: <dynamic>[
        Provider<DatabaseService>.value(value: dbService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(dbService),
        ),
        ChangeNotifierProvider<FinanceProvider>(
          create: (_) => FinanceProvider(dbService)..loadInitialData(),
        ),
      ],
      child: const PocketLedgerApp(),
    ),
  );
}

/// The root application widget configuring themes, navigation, and initial routing.
class PocketLedgerApp extends StatelessWidget {
  const PocketLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();

    // Deep navy and emerald color palette
    const Color deepNavy = Color(0xFF0F172A);
    const Color emeraldAccent = Color(0xFF10B981);

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepNavy,
        brightness: Brightness.light,
        primary: const Color(0xFF1E293B),
        secondary: emeraldAccent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: emeraldAccent.withOpacity(0.18),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF0F172A));
          }
          return const IconThemeData(color: Color(0xFF64748B));
        }),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepNavy,
        brightness: Brightness.dark,
        primary: const Color(0xFF38BDF8),
        secondary: emeraldAccent,
        surface: const Color(0xFF1E293B),
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: const CardTheme(
        elevation: 0,
        color: Color(0xFF1E293B),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 2,
        indicatorColor: emeraldAccent.withOpacity(0.24),
        iconTheme: WidgetStateProperty.resolveWith((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return const IconThemeData(color: Color(0xFF94A3B8));
        }),
      ),
    );

    return MaterialApp(
      title: 'PocketLedger',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const _AppRoot(),
    );
  }
}

/// Helper deciding whether to route to Onboarding or Main Shell based on initial database state.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (BuildContext context, FinanceProvider finance, Widget? child) {
        if (finance.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PocketLedger...'),
                ],
              ),
            ),
          );
        }

        if (!finance.onboardingCompleted) {
          return const OnboardingScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
