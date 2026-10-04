import 'package:shared_preferences/shared_preferences.dart';

class MidwifeSession {
  const MidwifeSession({
    required this.token,
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  final String token;
  final String id;
  final String firstName;
  final String lastName;

  String get displayName => '$firstName $lastName';
}

class SessionStore {
  static const _token = 'auth_token';
  static const _id = 'midwife_id';
  static const _first = 'midwife_first_name';
  static const _last = 'midwife_last_name';

  Future<MidwifeSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_token);
    final id = prefs.getString(_id);
    final first = prefs.getString(_first);
    final last = prefs.getString(_last);
    if (token == null || id == null || first == null || last == null || token.isEmpty) {
      return null;
    }
    return MidwifeSession(token: token, id: id, firstName: first, lastName: last);
  }

  Future<void> write(MidwifeSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_token, session.token);
    await prefs.setString(_id, session.id);
    await prefs.setString(_first, session.firstName);
    await prefs.setString(_last, session.lastName);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_token);
    await prefs.remove(_id);
    await prefs.remove(_first);
    await prefs.remove(_last);
  }
}
