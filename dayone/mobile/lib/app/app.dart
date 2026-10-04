import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/session_store.dart';
import '../features/auth/splash_screen.dart';
import 'theme.dart';

class DayOneApp extends StatefulWidget {
  const DayOneApp({super.key, this.apiClient, this.sessionStore});

  final ApiClient? apiClient;
  final SessionStore? sessionStore;

  @override
  State<DayOneApp> createState() => _DayOneAppState();
}

class _DayOneAppState extends State<DayOneApp> {
  late final AuthController _auth = AuthController(
    api: widget.apiClient ?? ApiClient(),
    store: widget.sessionStore ?? SessionStore(),
  );

  @override
  void initState() {
    super.initState();
    _auth.bootstrap();
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _auth,
      child: MaterialApp(
        title: 'DayOne',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
