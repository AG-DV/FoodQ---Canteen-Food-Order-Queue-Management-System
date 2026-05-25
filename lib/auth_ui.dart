import 'package:flutter/material.dart';
import 'auth.dart';

/// Global authentication service instance.
final AuthService authService = AuthService();

/// Simple authentication UI with registration and login.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Toggle between register and login modes.
  bool _isRegister = true;

  // Controllers for input fields.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
    });
  }

  void _register() {
    try {
      final user = authService.register(
        name: _nameController.text,
        email: _emailController.text,
        role: _roleController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered: ${user.email}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _login() {
    final user = authService.login(
      _emailController.text,
      _passwordController.text,
    );
    if (user != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged in as ${user.name} (role: ${user.role})')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegister ? 'Register' : 'Login'),
        actions: [
          TextButton(
            onPressed: _toggleMode,
            child: Text(_isRegister ? 'Login' : 'Register', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_isRegister) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            if (_isRegister) ...[
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRegister ? _register : _login,
              child: Text(_isRegister ? 'Register' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }
}

