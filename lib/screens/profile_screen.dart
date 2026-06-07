import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _profile;
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _auth.getProfile();
      setState(() {
        _profile = data;
        _nameCtrl.text = data['name'] ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _auth.updateProfile(name: _nameCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      initialValue: _profile?['email'] ?? '',
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_profile?['role'] != null)
                      Chip(
                        label: Text(
                          (_profile!['role'] as String).toUpperCase(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        avatar: const Icon(Icons.badge_outlined, size: 16),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
