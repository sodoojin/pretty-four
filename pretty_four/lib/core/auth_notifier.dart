import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authNotifier = AuthNotifier();

class AuthNotifier extends ChangeNotifier {
  static const _key = 'access_token';
  static const _introKey = 'intro_seen';
  final _storage = const FlutterSecureStorage();

  String? _token;
  bool _initialized = false;
  bool _introSeen = false;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  bool get initialized => _initialized;

  /// 온보딩(인트로)을 이미 봤는지 — 최초 1회만 노출하기 위한 플래그.
  bool get introSeen => _introSeen;

  Future<void> init() async {
    _token = await _storage.read(key: _key);
    _introSeen = (await _storage.read(key: _introKey)) == 'true';
    _initialized = true;
    notifyListeners();
  }

  Future<void> markIntroSeen() async {
    await _storage.write(key: _introKey, value: 'true');
    _introSeen = true;
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: _key, value: token);
    _token = token;
    notifyListeners();
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _key);
    _token = null;
    notifyListeners();
  }
}
