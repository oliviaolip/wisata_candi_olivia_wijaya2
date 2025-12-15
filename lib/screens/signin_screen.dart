import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  String _error = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final prefs = await SharedPreferences.getInstance();
    final keyString = prefs.getString('key');
    final ivString = prefs.getString('iv');
    final storedUser = prefs.getString('username');
    final storedPass = prefs.getString('password');

    if (keyString == null ||
        ivString == null ||
        storedUser == null ||
        storedPass == null) {
      setState(
        () => _error = 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.',
      );
      return;
    }

    try {
      final key = encrypt.Key.fromBase64(keyString);
      final iv = encrypt.IV.fromBase64(ivString);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final decryptedUser = encrypter.decrypt64(storedUser, iv: iv);
      final decryptedPass = encrypter.decrypt64(storedPass, iv: iv);

      if (_usernameController.text.trim() == decryptedUser &&
          _passwordController.text == decryptedPass) {
        await prefs.setBool('isSignedIn', true);
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } else {
        setState(() => _error = 'Username atau password salah.');
      }
    } catch (e) {
      setState(() => _error = 'Gagal masuk: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _signIn, child: const Text('Sign In')),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
