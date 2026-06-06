import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manager/manager_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore session from local storage before rendering anything
  await AuthService().loadSession();
  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canteen App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      // Auth gate: show Home if session exists, otherwise Login
      home: !AuthService().isLoggedIn
          ? const LoginScreen()
          : AuthService().isManager
              ? const ManagerHomeScreen()
              : const HomeScreen(),
    );
  }
}
