import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserProfile {
  final String userId;
  String name;
  String phone;
  String email;
  String address;
  String location;
  bool isLoggedIn;
  String? authToken;

  UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.location,
    this.isLoggedIn = false,
    this.authToken,
  });
}

class AuthResponse {
  final bool success;
  final String message;
  final String? token;
  final int? expiresInSeconds;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.expiresInSeconds,
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

  // Base URL configuration:
  // - Android emulator: http://10.0.2.2:5000
  // - iOS Simulator / Windows / Web: http://localhost:5000
  String _baseUrl = !kIsWeb && Platform.isAndroid 
      ? 'http://10.0.2.2:5000' 
      : 'http://localhost:5000';

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    _baseUrl = url;
    notifyListeners();
  }

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
              authToken: data['auth_token'] as String?,
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
        'is_logged_in': _user.isLoggedIn,
        'user_id': _user.userId,
        'user_name': _user.name,
        'user_phone': _user.phone,
        'user_email': _user.email,
        'user_address': _user.address,
        'user_location': _user.location,
        'auth_token': _user.authToken,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      if (kDebugMode) {
        print("Error saving auth session: $e");
      }
    }
  }

  /// 1. Send OTP to email via Node.js Express Backend
  /// Calls POST /api/send-email-otp
  Future<AuthResponse> sendOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim();
    final url = Uri.parse('$_baseUrl/api/send-email-otp');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = response.statusCode == 200 && (data['success'] == true);
      final message = data['message'] as String? ?? (success ? 'OTP sent successfully.' : 'Failed to send OTP.');

      if (success) {
        _pendingEmail = cleanEmail;
        _isOtpSent = true;
      } else {
        _isOtpSent = false;
      }

      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: success,
        message: message,
        expiresInSeconds: data['expiresInSeconds'] as int? ?? 300,
      );
    } catch (e) {
      _isLoading = false;
      _isOtpSent = false;
      notifyListeners();

      return AuthResponse(
        success: false,
        message: 'Cannot connect to server. Please ensure backend is running.',
      );
    }
  }

  /// 2. Resend OTP to email
  /// Calls POST /api/resend-email-otp
  Future<AuthResponse> resendOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim();
    final url = Uri.parse('$_baseUrl/api/resend-email-otp');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = response.statusCode == 200 && (data['success'] == true);
      final message = data['message'] as String? ?? (success ? 'OTP resent successfully.' : 'Failed to resend OTP.');

      if (success) {
        _pendingEmail = cleanEmail;
      }

      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: success,
        message: message,
        expiresInSeconds: data['expiresInSeconds'] as int? ?? 300,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: false,
        message: 'Cannot connect to server. Please try again.',
      );
    }
  }

  /// 3. Verify OTP against MySQL backend
  /// Calls POST /api/verify-email-otp
  Future<AuthResponse> verifyOtp(String otp) async {
    _isLoading = true;
    notifyListeners();

    final email = _pendingEmail ?? _user.email;
    final cleanOtp = otp.trim();
    final url = Uri.parse('$_baseUrl/api/verify-email-otp');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otp': cleanOtp,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = response.statusCode == 200 && (data['success'] == true);
      final message = data['message'] as String? ?? (success ? 'Verified successfully.' : 'Wrong OTP');
      final token = data['token'] as String?;

      if (success) {
        _user.isLoggedIn = true;
        _user.email = email;
        _user.authToken = token;
        await _saveSession();
      }

      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: success,
        message: message,
        token: token,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: false,
        message: 'Cannot connect to server. Please try again.',
      );
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
      authToken: _user.authToken,
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
    _user.authToken = null;
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
