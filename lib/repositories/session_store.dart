import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/auth_models.dart';

/// Persists the signed-in session in a `hive_ce` box so a page refresh does not
/// log the user out.
///
/// Only the token, the user object and the token's expiry are stored — the
/// password is never written here, and the token is never logged.
///
/// The session is held in memory and hydrated from the box once on construction;
/// the box is a write-behind cache. Readers therefore never observe a half-
/// applied change while Hive flushes to disk, which matters because the Dio
/// error interceptor clears the session from inside an error handler and
/// [AuthNotifier] must see it gone immediately.
class SessionStore extends ChangeNotifier {
  SessionStore(this._box) {
    _token = _readString(_tokenKey);
    _user = _readUser();
    final expiresAt = _box.get(_expiresAtKey);
    _expiresAt = expiresAt is int ? expiresAt : null;
  }

  final Box<dynamic> _box;

  static const String boxName = 'stark_vms_session';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _expiresAtKey = 'auth_expires_at';

  String? _token;
  AuthUser? _user;
  int? _expiresAt;

  String? _readString(String key) {
    final raw = _box.get(key);
    return (raw is String && raw.isNotEmpty) ? raw : null;
  }

  AuthUser? _readUser() {
    final raw = _readString(_userKey);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// The stored Bearer token, or `null` when signed out or expired.
  String? get token => isExpired ? null : _token;

  /// Whether the stored token is past the expiry the server reported.
  /// Checked locally so an obviously dead token is dropped without a round trip.
  bool get isExpired {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch >= expiresAt;
  }

  /// The cached user, used to render the shell before `/auth/me` confirms it.
  AuthUser? get user => _user;

  Future<void> save({
    required String token,
    required AuthUser user,
    int? expiresInSeconds,
  }) async {
    _token = token;
    _user = user;
    _expiresAt = expiresInSeconds == null
        ? null
        : DateTime.now()
              .add(Duration(seconds: expiresInSeconds))
              .millisecondsSinceEpoch;
    notifyListeners();

    final writes = <String, dynamic>{
      _tokenKey: token,
      _userKey: jsonEncode(user.toJson()),
    };
    if (_expiresAt != null) {
      writes[_expiresAtKey] = _expiresAt;
      await _box.putAll(writes);
    } else {
      await _box.putAll(writes);
      await _box.delete(_expiresAtKey);
    }
  }

  /// Caches a refreshed user without touching the token.
  ///
  /// Skips the write when the cached copy is already identical, which is the
  /// common case on start-up — `/auth/me` usually returns what is already
  /// stored, and there is no reason to touch the disk or wake listeners.
  Future<void> updateUser(AuthUser user) async {
    final encoded = jsonEncode(user.toJson());
    if (_box.get(_userKey) == encoded) {
      _user = user;
      return;
    }
    _user = user;
    notifyListeners();
    await _box.put(_userKey, encoded);
  }

  Future<void> clear() async {
    _token = null;
    _user = null;
    _expiresAt = null;
    // Listeners must see the session gone before the flush completes.
    notifyListeners();
    await _box.deleteAll(<String>[_tokenKey, _userKey, _expiresAtKey]);
  }
}
