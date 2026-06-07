import 'package:flutter/material.dart';
import 'screens/manager/manager_home_screen.dart';
import 'features/vendor/vendor_home_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService().loadSession();
  runApp(const CanteenApp());
}

class CanteenApp extends StatelessWidget {
  const CanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodQ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: _resolveHome(),
    );
  }

  Widget _resolveHome() {
    final auth = AuthService();
    if (!auth.isLoggedIn) return const LoginScreen();
    switch (auth.role) {
      case 'vendor':  return const VendorHomeScreen();
      case 'manager': return const ManagerHomeScreen();
      default:        return const HomeScreen();
    }
  }
}
