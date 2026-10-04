import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../shared/dayone_widgets.dart';
import '../chat/chat_screen.dart';
import 'auth_controller.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final first = _first.text.trim();
    final last = _last.text.trim();
    final password = _password.text;
    if (first.length < 2 || last.length < 2 || password.isEmpty) {
      setState(() => _error = 'Indiquez votre prénom, votre nom et votre mot de passe.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).login(firstName: first, lastName: last, password: password);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const ChatScreen()), (_) => false);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(gradient: DayOneColors.gradient, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.local_florist_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Connexion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: DayOneColors.text, letterSpacing: -0.4)),
                      SizedBox(height: 2),
                      Text('Compte de la sage-femme', style: TextStyle(color: DayOneColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            DayOneField(label: 'Prénom', controller: _first, hint: 'Aïcha', textInputAction: TextInputAction.next),
            DayOneField(label: 'Nom', controller: _last, hint: 'Ndiaye', textInputAction: TextInputAction.next),
            DayOneField(
              label: 'Mot de passe',
              controller: _password,
              hint: '8 caractères minimum',
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: DayOneColors.muted),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(_error!, style: const TextStyle(color: DayOneColors.danger, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            DayOneButton(label: 'Entrer', icon: Icons.lock_open_rounded, busy: _busy, onPressed: _busy ? null : _submit),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text(
                'Créer un compte',
                style: TextStyle(color: DayOneColors.primaryDark, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Le mot de passe est vérifié par le serveur.\nRien n’est stocké en clair.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DayOneColors.muted, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
