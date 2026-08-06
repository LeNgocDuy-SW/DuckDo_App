import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final String provider; // 'email', 'google', 'facebook'

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

  factory UserModel.fromFirebase(User user, String provider) => UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Vịt Vàng Member',
        photoUrl: user.photoURL ?? '',
        provider: provider,
      );
}

class AuthService {
  static const String _userKey = 'duckdo_current_user';
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel?> getCurrentUser() async {
    // Kiểm tra Firebase Auth trước
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final provider = _getProviderFromFirebase(firebaseUser);
      _currentUser = UserModel.fromFirebase(firebaseUser, provider);
      await _saveUser(_currentUser!);
      return _currentUser;
    }

    // Fallback: đọc từ SharedPreferences (chế độ offline/khách)
    if (_currentUser != null) return _currentUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null && userStr.isNotEmpty) {
        _currentUser = UserModel.fromJson(json.decode(userStr));
      }
    } catch (e) {
      debugPrint('Lỗi đọc user local: $e');
    }
    return _currentUser;
  }

  String _getProviderFromFirebase(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'google';
      if (info.providerId == 'facebook.com') return 'facebook';
    }
    return 'email';
  }

  Future<void> _saveUser(UserModel user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  // ─── ĐĂNG NHẬP EMAIL/MẬT KHẨU ─────────────────────────────────────────────

  Future<UserModel> signInWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel.fromFirebase(credential.user!, 'email');
    await _saveUser(user);
    return user;
  }

  Future<UserModel> signUpWithEmail(
      String email, String password, String displayName) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Cập nhật displayName vào Firebase profile
    await credential.user!.updateDisplayName(
      displayName.isNotEmpty ? displayName : 'Vịt Vàng Member',
    );
    await credential.user!.reload();
    final updatedUser = _firebaseAuth.currentUser!;
    final user = UserModel.fromFirebase(updatedUser, 'email');
    await _saveUser(user);
    return user;
  }

  // ─── ĐĂNG NHẬP GOOGLE THẬT ─────────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    // Bắt đầu luồng đăng nhập Google - sẽ hiện popup chọn tài khoản thật
    final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

    if (googleAccount == null) {
      throw Exception('Người dùng đã hủy đăng nhập Google.');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleAccount.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final user = UserModel.fromFirebase(userCredential.user!, 'google');
    await _saveUser(user);
    return user;
  }

  // ─── ĐĂNG NHẬP FACEBOOK (Placeholder - cần fb_sdk nếu dùng thật) ──────────

  Future<UserModel> signInWithFacebook() async {
    // TODO: Tích hợp flutter_facebook_auth để đăng nhập Facebook thật
    // Hiện tại trả về thông báo chưa hỗ trợ
    throw Exception(
        'Đăng nhập Facebook chưa được kích hoạt. Vui lòng dùng Google hoặc Email.');
  }

  // ─── ĐĂNG XUẤT ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
