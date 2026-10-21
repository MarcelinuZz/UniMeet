import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final ValueNotifier<UserModel?> currentUserNotifier = ValueNotifier<UserModel?>(null);

  static const String _activeUserKey = 'unimeet_active_user';
  static const String _userStorePrefix = 'unimeet_user_';
  static const String _backendBaseUrl = 'http://localhost:3000/api/v1';

  // In-memory fallback cache to ensure zero crashes even if platform plugins are rebinding
  static final Map<String, String> _memoryStorage = {};

  UserModel? get currentUser => currentUserNotifier.value;

  Future<String?> _getStorageString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(key);
      if (val != null) {
        _memoryStorage[key] = val;
        return val;
      }
    } catch (_) {
      // Fallback to in-memory store if plugin channel is not registered
    }
    return _memoryStorage[key];
  }

  Future<void> _setStorageString(String key, String value) async {
    _memoryStorage[key] = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Fallback in-memory
    }
  }

  Future<void> _removeStorageString(String key) async {
    _memoryStorage.remove(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {
      // Fallback in-memory
    }
  }

  Future<void> init() async {
    try {
      final activeUserJson = await _getStorageString(_activeUserKey);
      if (activeUserJson != null) {
        currentUserNotifier.value = UserModel.fromJson(activeUserJson);
      }
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
    }
  }

  Future<UserModel> loginOrCreateAccount({
    required String email,
    String? nim,
    String? name,
    String? campus,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final isMelvin = cleanEmail.contains('melvin.goh') || cleanEmail.contains('melvin');
    final isMarcelinus = cleanEmail.contains('marcelinus');
    final defaultNim = isMelvin ? '2802436181' : '2602194831';
    final cleanNim = (nim != null && nim.trim().isNotEmpty) ? nim.trim() : defaultNim;
    final defaultName = isMelvin
        ? 'Melvin Goh'
        : (isMarcelinus ? 'Marcelinus Wijaya Oey' : 'Marcelinus Wijaya Oey');
    final derivedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : defaultName;
    final initials = UserModel.extractInitials(derivedName);
    final activeCampus = (campus != null && campus.isNotEmpty) ? campus : 'BINUS Anggrek Campus';

    final existingUserJson = await _getStorageString('$_userStorePrefix$cleanEmail');

    UserModel user;

    if (existingUserJson != null) {
      // Existing user found in storage - ensure entered NIM and Name are updated
      user = UserModel.fromJson(existingUserJson);
      user = user.copyWith(
        nim: cleanNim,
        name: derivedName,
        avatarInitials: initials,
      );
      await _setStorageString('$_userStorePrefix$cleanEmail', user.toJson());
    } else {
      // Check backend SSO endpoint
      try {
        final response = await http
            .post(
              Uri.parse('$_backendBaseUrl/auth/sso/binusmaya'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({
                'ssoTicket': 'DEV_PORTAL_TICKET_${DateTime.now().millisecondsSinceEpoch}',
                'email': cleanEmail,
                'nim': cleanNim,
              }),
            )
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final resData = json.decode(response.body);
          final backendUser = resData['user'] ?? {};
          user = UserModel(
            id: backendUser['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            name: backendUser['name'] ?? derivedName,
            email: backendUser['email'] ?? cleanEmail,
            nim: backendUser['nim'] ?? cleanNim,
            major: backendUser['major'] ?? (isMelvin ? 'Cyber Security' : 'Computer Science'),
            batch: backendUser['batch'] ?? (isMelvin ? "Cyber Sec '24" : '2024'),
            campus: backendUser['campus'] ?? activeCampus,
            avatarInitials: backendUser['avatarInitials'] ?? initials,
            isVerified: backendUser['isVerified'] ?? true,
          );
        } else {
          user = _createNewLocalUser(cleanEmail, cleanNim, derivedName, initials, activeCampus);
        }
      } catch (_) {
        // Offline or backend unreachable, create local persistent account
        user = _createNewLocalUser(cleanEmail, cleanNim, derivedName, initials, activeCampus);
      }

      // Save to user store
      await _setStorageString('$_userStorePrefix$cleanEmail', user.toJson());
    }

    // Set as active logged in user
    await _setStorageString(_activeUserKey, user.toJson());
    currentUserNotifier.value = user;

    return user;
  }

  UserModel _createNewLocalUser(
    String email,
    String nim,
    String name,
    String initials,
    String campus,
  ) {
    final isMelvin = email.contains('melvin') || name.toLowerCase().contains('melvin');
    return UserModel(
      id: isMelvin ? 'usr_melvin' : 'usr_marcelinus',
      name: isMelvin ? 'Melvin Goh' : 'Marcelinus Wijaya Oey',
      email: isMelvin ? 'melvin.goh@binus.ac.id' : 'marcelinus.oey@binus.ac.id',
      nim: isMelvin ? '2802436181' : '2602194831',
      major: isMelvin ? 'Cyber Security' : 'Computer Science',
      batch: isMelvin ? "Cyber Sec '24" : "CS '24",
      campus: campus,
      avatarInitials: isMelvin ? 'MG' : 'MW',
      isVerified: true,
      interests: isMelvin
          ? ['Cyber Security', 'Valorant', 'Fore Coffee', 'Offensive Security']
          : ['Badminton', 'Flutter Mobile', 'Calculus II', 'Cloud Computing'],
      meetupsJoined: 2,
      hostedCount: 2,
      karma: 5.0,
    );
  }

  Future<void> updateActiveUser(UserModel updated) async {
    await _setStorageString('$_userStorePrefix${updated.email}', updated.toJson());
    await _setStorageString(_activeUserKey, updated.toJson());
    currentUserNotifier.value = updated;
  }

  Future<void> logout() async {
    await _removeStorageString(_activeUserKey);
    currentUserNotifier.value = null;
  }
}
