// ignore_for_file: prefer_initializing_formals

import 'package:flutter/widgets.dart';

import '../../core/network/api_client.dart';
import 'session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({required ApiClient api, required SessionStore store})
      : _api = api,
        _store = store;

  final ApiClient _api;
  final SessionStore _store;

  MidwifeSession? session;
  bool ready = false;

  Future<void> bootstrap() async {
    final saved = await _store.read();
    if (saved != null) {
      session = saved;
      _api.setToken(saved.token);
      try {
        final me = await _api.me();
        session = MidwifeSession(
          token: saved.token,
          id: me.id,
          firstName: me.firstName,
          lastName: me.lastName,
        );
        await _store.write(session!);
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          session = null;
          _api.setToken(null);
          await _store.clear();
        }
      } catch (_) {
        // Hors ligne : la session locale reste valable.
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final payload = await _api.register(firstName: firstName, lastName: lastName, password: password);
    await _keep(payload);
  }

  Future<void> login({
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    final payload = await _api.login(firstName: firstName, lastName: lastName, password: password);
    await _keep(payload);
  }

  Future<void> logout() async {
    session = null;
    _api.setToken(null);
    await _store.clear();
    notifyListeners();
  }

  Future<void> _keep(AuthPayload payload) async {
    session = MidwifeSession(
      token: payload.accessToken,
      id: payload.midwife.id,
      firstName: payload.midwife.firstName,
      lastName: payload.midwife.lastName,
    );
    await _store.write(session!);
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({super.key, required AuthController controller, required super.child})
      : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope introuvable');
    return scope!.notifier!;
  }
}
