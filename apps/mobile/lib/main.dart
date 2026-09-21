import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/providers/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';
import 'features/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const DarbApp(),
    ),
  );
}

class DarbApp extends StatelessWidget {
  const DarbApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'دَرْب — DARB',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // Arabic-First RTL Configuration
      locale: Locale(appState.currentLanguage, 'IQ'),
      supportedLocales: const [
        Locale('ar', 'IQ'),
        Locale('ku', 'IQ'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      home: appState.isAuthenticated
          ? const HomeScreen()
          : LoginScreen(onLoginSuccess: () => appState.loadInitialData()),
    );
  }
}
