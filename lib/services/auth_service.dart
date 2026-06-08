import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyUserId = 'user_id';
  static const _keyUserNama = 'user_nama';
  static const _keyUserRole = 'user_role';

  Future<Map<String, String>?> login(String email, String password) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (rows.isEmpty) return null;

    final user = rows.first;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user['id'] as String);
    await prefs.setString(_keyUserNama, user['nama'] as String);
    await prefs.setString(_keyUserRole, user['role'] as String);

    return {
      'id': user['id'] as String,
      'nama': user['nama'] as String,
      'role': user['role'] as String,
    };
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyUserId);
    if (id == null) return null;
    return {
      'id': id,
      'nama': prefs.getString(_keyUserNama) ?? '',
      'role': prefs.getString(_keyUserRole) ?? 'anggota',
    };
  }

  Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session != null;
  }
}