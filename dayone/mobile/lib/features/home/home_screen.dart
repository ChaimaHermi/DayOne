import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  bool _loading = false;
  String? _message;
  bool _success = false;

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    String message;
    bool success = false;
    try {
      success = await _apiClient.checkHealth();
      message = success ? 'Backend connected' : 'Unexpected response from backend';
    } on DioException catch (e) {
      message = 'Connection failed: ${e.message ?? e.type.name}';
    } catch (e) {
      message = 'Connection failed: $e';
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _success = success;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DayOne',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 48),
                FilledButton(
                  onPressed: _loading ? null : _testConnection,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Test Backend Connection'),
                ),
                const SizedBox(height: 24),
                if (_message != null)
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _success ? Colors.green.shade700 : theme.colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _apiClient.baseUrl,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
