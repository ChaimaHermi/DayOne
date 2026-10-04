import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/network/api_client.dart';
import '../../shared/dayone_widgets.dart';
import '../chat/chat_screen.dart';
import 'auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final first = _first.text.trim();
    final last = _last.text.trim();
    final password = _password.text;
    if (first.length < 2 || last.length < 2) {
      setState(() => _error = 'Le prénom et le nom doivent contenir au moins 2 caractères.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthScope.of(context).register(firstName: first, lastName: last, password: password);
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
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded, color: DayOneColors.primary),
              ),
            ),
            const Text(
              'Créer mon compte',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: DayOneColors.text, letterSpacing: -0.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Prénom, nom et mot de passe. Ce compte ouvre la discussion sur cet appareil.',
              style: TextStyle(color: DayOneColors.muted, height: 1.4),
            ),
            const SizedBox(height: 22),
            DayOneField(label: 'Prénom', controller: _first, hint: 'Aïcha', textInputAction: TextInputAction.next),
            DayOneField(label: 'Nom', controller: _last, hint: 'Ndiaye', textInputAction: TextInputAction.next),
            DayOneField(
              label: 'Mot de passe',
              controller: _password,
              hint: '8 caractères minimum',
              obscure: _obscure,
              textInputAction: TextInputAction.next,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: DayOneColors.muted),
              ),
            ),
            DayOneField(
              label: 'Confirmer le mot de passe',
              controller: _confirm,
              obscure: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: DayOneColors.danger, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 12),
            ],
            DayOneButton(label: 'Créer le compte', icon: Icons.person_add_alt_1_rounded, busy: _busy, onPressed: _busy ? null : _submit),
          ],
        ),
      ),
    );
  }
}
