import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class UserProfile {
  final String userId;
  String name;
  String phone;
  String email;
  String address;
  String location;
  bool isLoggedIn;

  UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.location,
    this.isLoggedIn = false,
  });
}

class AuthService extends ChangeNotifier {
  UserProfile _user = UserProfile(
    userId: "U001",
    name: "Mani Kumar",
    phone: "+91 98402 33421",
    email: "mani.chennai@example.com",
    address: "14/2, Usman Road, T. Nagar, Chennai - 600017",
    location: "T. Nagar, Chennai",
    isLoggedIn: false,
  );

  String? _pendingEmail;
  bool _isOtpSent = false;
  bool _isLoading = false;

  UserProfile get currentUser => _user;
  bool get isLoggedIn => _user.isLoggedIn;
  bool get isOtpSent => _isOtpSent;
  bool get isLoading => _isLoading;
  String? get pendingEmail => _pendingEmail;

  AuthService() {
    initSession();
  }

  Future<File> _getSessionFile() async {
    try {
      final sysTemp = Directory.systemTemp;
      return File('${sysTemp.path}/advt_app_session.json');
    } catch (_) {
      return File('advt_app_session.json');
    }
  }

  /// Load session state upon initialization or app launch.
  Future<void> initSession() async {
    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final isLoggedIn = data['is_logged_in'] as bool? ?? false;
          if (isLoggedIn) {
            _user = UserProfile(
              userId: data['user_id'] as String? ?? "U001",
              name: data['user_name'] as String? ?? "Mani Kumar",
              phone: data['user_phone'] as String? ?? "+91 98402 33421",
              email: data['user_email'] as String? ?? "mani.chennai@example.com",
              address: data['user_address'] as String? ?? "14/2, Usman Road, T. Nagar, Chennai - 600017",
              location: data['user_location'] as String? ?? "T. Nagar, Chennai",
              isLoggedIn: true,
            );
            notifyListeners();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading auth session: $e");
      }
    }
  }

  /// Save session state persistently.
  Future<void> _saveSession() async {
    try {
      final file = await _getSessionFile();
      final data = {
        'is_logged_in': true,
        'user_id': _user.userId,
        'user_name': _user.name,
        'user_phone': _user.phone,
        'user_email': _user.email,
        'user_address': _user.address,
        'user_location': _user.location,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      if (kDebugMode) {
        print("Error saving auth session: $e");
      }
    }
  }

  /// Purpose: Send OTP to the entered email address.
  Future<bool> sendOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _pendingEmail = email;
    _isOtpSent = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Purpose: Verify the entered 6-digit OTP code.
  Future<bool> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _isLoading = false;
    if (otp == "123456") {
      _user.isLoggedIn = true;
      if (_pendingEmail != null) {
        _user.email = _pendingEmail!;
      }
      await _saveSession();
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  /// Purpose: Register a new user with personal details.
  Future<void> registerUser({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String location,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    _user = UserProfile(
      userId: "U${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      phone: phone,
      email: email,
      address: address,
      location: location,
      isLoggedIn: true,
    );

    await _saveSession();
    _isLoading = false;
    notifyListeners();
  }

  /// Purpose: Update current user profile details.
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
  }) async {
    _user.name = name;
    _user.phone = phone;
    _user.email = email;
    _user.address = address;
    await _saveSession();
    notifyListeners();
  }

  /// Purpose: Logout current user and clear session.
  Future<void> logout() async {
    _user.isLoggedIn = false;
    _isOtpSent = false;
    _pendingEmail = null;
    try {
      final file = await _getSessionFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing session: $e");
      }
    }
    notifyListeners();
  }
}
