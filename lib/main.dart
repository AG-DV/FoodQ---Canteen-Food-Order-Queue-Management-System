import 'package:flutter/material.dart';
import 'auth.dart';
import 'auth_ui.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
final AuthService _authService = AuthService();


Future<void> _ensureDummyAccounts() async {
  final dummyAccounts = [
    {
      'email': 'test1@example.com',
      'password': 'password123',
      'name': 'Test User1',
    },
    {
      'email': 'test2@example.com',
      'password': 'password456',
      'name': 'Test User2',
    },
  ];

  for (var acct in dummyAccounts) {
    try {
      await _authService.register(
        name: acct['name']!,
        email: acct['email']!,
        role: '',
        phone: '',
        password: acct['password']!,
      );
    } catch (e) {
      // Ignore errors (e.g., duplicate accounts).
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _ensureDummyAccounts();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/login': (context) => const AuthPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const MyHomePage(title: 'Flutter Demo Home Page'),
      },
      // Use the login page as the default entry point.
      home: const AuthPage(),
    );
  }
}

// Keep the existing MyHomePage unchanged.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Auth UI'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
