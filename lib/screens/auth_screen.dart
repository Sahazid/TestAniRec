import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'admin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool signupMode = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final state = context.read<AppState>();
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    bool ok = false;
    if (signupMode) {
      ok = await state.signup(email: email, password: password);
    } else {
      ok = await state.login(email: email, password: password);
    }
    if (!mounted) return;
    if (ok) {
      if (state.currentUser?.isAdmin == true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _forgot(BuildContext context) async {
    final state = context.read<AppState>();
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    final ok = await state.forgotPassword(email, password);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Login now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(signupMode ? 'Sign Up' : 'Login')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Mail'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.authBusy ? null : () => _forgot(context),
            child: const Text('Forgot Password'),
          ),
          if (state.authError != null) ...[
            const SizedBox(height: 8),
            Text(state.authError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.authBusy ? null : () => _submit(context),
            child: Text(signupMode ? 'Sign Up' : 'Login'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.authBusy ? null : () => setState(() => signupMode = !signupMode),
            child: Text(signupMode ? 'I already have an account • Login' : "I don't have an account • Signup"),
          ),
        ],
      ),
    );
  }
}
