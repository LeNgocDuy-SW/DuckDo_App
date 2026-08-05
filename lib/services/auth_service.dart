import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String provider; // 'email', 'google', 'facebook', 'guest'

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.provider,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'provider': provider,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Vịt Vàng Member',
        photoUrl: json['photoUrl'] as String? ?? '',
        provider: json['provider'] as String? ?? 'email',
      );
}

class AuthService {
  static const String _userKey = 'duckdo_current_user';
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null && userStr.isNotEmpty) {
        _currentUser = UserModel.fromJson(json.decode(userStr));
      }
    } catch (e) {
      debugPrint('Lỗi đọc user: $e');
    }
    return _currentUser;
  }

  Future<void> _saveUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Giả lập network delay
    final String name = email.contains('@') ? email.split('@')[0] : email;
    final user = UserModel(
      uid: 'user_${email.hashCode}',
      email: email,
      displayName: name,
      photoUrl: '',
      provider: 'email',
    );
    await _saveUser(user);
    return user;
  }

  Future<UserModel> signUpWithEmail(
      String email, String password, String displayName) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final user = UserModel(
      uid: 'user_${email.hashCode}',
      email: email,
      displayName: displayName.isNotEmpty ? displayName : 'Bạn Vịt Mới',
      photoUrl: '',
      provider: 'email',
    );
    await _saveUser(user);
    return user;
  }

  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = UserModel(
      uid: 'google_109283749',
      email: 'duckdo.user@gmail.com',
      displayName: 'DuckDo Google Fan 🐥',
      photoUrl: 'https://lh3.googleusercontent.com/a/default-avatar',
      provider: 'google',
    );
    await _saveUser(user);
    return user;
  }

  Future<UserModel> signInWithFacebook() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final user = UserModel(
      uid: 'fb_987654321',
      email: 'duckdo.fb@facebook.com',
      displayName: 'DuckDo FB Member 📘',
      photoUrl: 'https://platform-lookaside.fbsbx.com/platform/profilepic/',
      provider: 'facebook',
    );
    await _saveUser(user);
    return user;
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
