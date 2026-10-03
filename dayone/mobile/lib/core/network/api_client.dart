import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  /// Returns true when the backend answers `{"status": "ok"}`.
  Future<bool> checkHealth() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return response.data?['status'] == 'ok';
  }
}
