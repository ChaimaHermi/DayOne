import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 12),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Returns true when the backend answers `{"status": "ok"}`.
  Future<bool> checkHealth() async {
    final response = await _dio.get<Map<String, dynamic>>('/health');
    return response.data?['status'] == 'ok';
  }

  Future<AuthPayload> register({
    required String firstName,
    required String lastName,
    required String password,
  }) {
    return _auth('/auth/register', firstName: firstName, lastName: lastName, password: password);
  }

  Future<AuthPayload> login({
    required String firstName,
    required String lastName,
    required String password,
  }) {
    return _auth('/auth/login', firstName: firstName, lastName: lastName, password: password);
  }

  Future<MidwifeProfile> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return MidwifeProfile.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Future<AuthPayload> _auth(
    String path, {
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
        },
      );
      final payload = AuthPayload.fromJson(response.data ?? {});
      setToken(payload.accessToken);
      return payload;
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  ApiException _map(DioException error) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String, statusCode: status);
    }
    if (status == 422) {
      return ApiException('Vérifiez les champs saisis.', statusCode: status);
    }
    if (status == 401) {
      return ApiException('Session invalide.', statusCode: status);
    }
    return ApiException(
      'Connexion impossible. Vérifiez le réseau et réessayez.',
      statusCode: status,
    );
  }
}

class MidwifeProfile {
  const MidwifeProfile({required this.id, required this.firstName, required this.lastName});

  final String id;
  final String firstName;
  final String lastName;

  factory MidwifeProfile.fromJson(Map<String, dynamic> json) {
    return MidwifeProfile(
      id: json['id'].toString(),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
    );
  }
}

class AuthPayload {
  const AuthPayload({required this.accessToken, required this.midwife});

  final String accessToken;
  final MidwifeProfile midwife;

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    final midwife = json['midwife'];
    return AuthPayload(
      accessToken: json['access_token'] as String? ?? '',
      midwife: MidwifeProfile.fromJson(midwife is Map<String, dynamic> ? midwife : {}),
    );
  }
}
