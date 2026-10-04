import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/dayone_widgets.dart';
import '../chat/chat_screen.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  void _start(BuildContext context) {
    final auth = AuthScope.of(context);
    final next = auth.session == null ? const LoginScreen() : const ChatScreen();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: DayOneColors.gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                      ),
                      child: const Icon(Icons.local_florist_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text('DayOne', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const Spacer(),
                const Text(
                  'Le registre reste en papier.\nSes données, elles, suivent la femme.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Photographiez une page. L’agent la lit sur le téléphone, vous dit quand il doute, et vous gardez le dernier mot.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 15, height: 1.45),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _Chip('Hors ligne d’abord'),
                    _Chip('Vous confirmez'),
                    _Chip('Compte sage-femme'),
                  ],
                ),
                const SizedBox(height: 18),
                DayOneButton(
                  label: 'Commencer',
                  icon: Icons.arrow_forward_rounded,
                  variant: DayOneButtonVariant.white,
                  busy: !auth.ready,
                  onPressed: auth.ready ? () => _start(context) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
    );
  }
}
