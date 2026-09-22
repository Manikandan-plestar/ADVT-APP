import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class UserProfile {
  String userId;
  String name;
  String phone;
  String countryCode;
  String email;
  String address;
  String locality;
  String city;
  String state;
  String country;
  String location;
  bool isLoggedIn;
  String? authToken;

  UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    this.countryCode = '+91',
    required this.email,
    required this.address,
    this.locality = '',
    this.city = '',
    this.state = '',
    this.country = '',
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
  final bool isExistingUser;
  final Map<String, dynamic>? userData;

  AuthResponse({
    required this.success,
    required this.message,
    this.token,
    this.expiresInSeconds,
    this.isExistingUser = false,
    this.userData,
  });
}

class AuthService extends ChangeNotifier {
  UserProfile _user = UserProfile(
    userId: "",
    name: "",
    phone: "",
    countryCode: "+91",
    email: "",
    address: "",
    locality: "",
    city: "",
    state: "",
    country: "",
    location: "",
    isLoggedIn: false,
  );

  String? _pendingEmail;
  bool _isOtpSent = false;
  bool _isLoading = false;

  // Base URL configuration (delegated to unified ApiClient)
  String get _baseUrl => ApiClient().baseUrl;
  String get baseUrl => ApiClient().baseUrl;
  set baseUrl(String url) {
    ApiClient().setBaseUrl(url);
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
              userId: data['user_id'] as String? ?? "",
              name: data['user_name'] as String? ?? "",
              phone: data['user_phone'] as String? ?? "",
              countryCode: data['country_code'] as String? ?? "+91",
              email: data['user_email'] as String? ?? "",
              address: data['user_address'] as String? ?? "",
              locality: data['locality'] as String? ?? "",
              city: data['city'] as String? ?? "",
              state: data['state'] as String? ?? "",
              country: data['country'] as String? ?? "",
              location: data['user_location'] as String? ?? "",
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
        'country_code': _user.countryCode,
        'user_email': _user.email,
        'user_address': _user.address,
        'locality': _user.locality,
        'city': _user.city,
        'state': _user.state,
        'country': _user.country,
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

  /// 3. Verify OTP against MySQL backend & detect existing user
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
      final isExistingUser = data['isExistingUser'] == true;
      final userData = data['user'] as Map<String, dynamic>?;

      if (success) {
        if (isExistingUser && userData != null) {
          // Populate existing user profile from database
          _user = UserProfile(
            userId: userData['userId'] as String? ?? "U${userData['id'] ?? '001'}",
            name: userData['full_name'] as String? ?? "",
            phone: userData['mobile_number'] as String? ?? "",
            countryCode: userData['country_code'] as String? ?? "+91",
            email: userData['email'] as String? ?? email,
            address: userData['full_address'] as String? ?? "",
            locality: userData['locality'] as String? ?? "",
            city: userData['city'] as String? ?? "",
            state: userData['state'] as String? ?? "",
            country: userData['country'] as String? ?? "",
            location: (userData['city'] != null && (userData['city'] as String).isNotEmpty)
                ? (userData['city'] as String)
                : (userData['locality'] as String? ?? "Chennai"),
            isLoggedIn: true,
            authToken: token,
          );
        } else {
          // Prepare new user state with verified email
          _user.email = email;
          _user.authToken = token;
          _user.isLoggedIn = false; // Registration required before logged in
        }
        await _saveSession();
      }

      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: success,
        message: message,
        token: token,
        isExistingUser: isExistingUser,
        userData: userData,
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

  /// 4. Register a new user with personal details in MySQL `users` table
  /// Calls POST /api/register-user
  Future<AuthResponse> registerUser({
    required String name,
    required String phone,
    required String email,
    required String address,
    String countryCode = '+91',
    String locality = '',
    String city = '',
    String state = '',
    String country = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.trim();
    final url = Uri.parse('$_baseUrl/api/register-user');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': cleanEmail,
              'full_name': name.trim(),
              'mobile_number': phone.trim(),
              'country_code': countryCode.trim(),
              'full_address': address.trim(),
              'locality': locality.trim(),
              'city': city.trim(),
              'state': state.trim(),
              'country': country.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = (response.statusCode == 200 || response.statusCode == 201) && (data['success'] == true);
      final message = data['message'] as String? ?? (success ? 'User registered successfully!' : 'Failed to register.');
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (success) {
        final id = userData?['id'] ?? DateTime.now().millisecondsSinceEpoch;
        _user = UserProfile(
          userId: userData?['userId'] as String? ?? "U${id.toString().padLeft(3, '0')}",
          name: name.trim(),
          phone: phone.trim(),
          countryCode: countryCode.trim(),
          email: cleanEmail,
          address: address.trim(),
          locality: locality.trim(),
          city: city.trim(),
          state: state.trim(),
          country: country.trim(),
          location: city.isNotEmpty ? city : (locality.isNotEmpty ? locality : "Chennai"),
          isLoggedIn: true,
          authToken: token ?? _user.authToken,
        );

        await _saveSession();
      }

      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: success,
        message: message,
        token: token,
        userData: userData,
      );
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return AuthResponse(
        success: false,
        message: 'Cannot connect to server to save registration. Please try again.',
      );
    }
  }

  /// 5. Fetch user profile from database
  /// Calls GET /api/user-profile?email=...
  Future<void> fetchUserProfile() async {
    if (_user.email.isEmpty) return;

    final url = Uri.parse('$_baseUrl/api/user-profile?email=${Uri.encodeComponent(_user.email)}');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          _user.userId = userData['userId'] as String? ?? _user.userId;
          _user.name = userData['full_name'] as String? ?? _user.name;
          _user.phone = userData['mobile_number'] as String? ?? _user.phone;
          _user.countryCode = userData['country_code'] as String? ?? _user.countryCode;
          _user.address = userData['full_address'] as String? ?? _user.address;
          _user.locality = userData['locality'] as String? ?? _user.locality;
          _user.city = userData['city'] as String? ?? _user.city;
          _user.state = userData['state'] as String? ?? _user.state;
          _user.country = userData['country'] as String? ?? _user.country;
          _user.location = _user.city.isNotEmpty ? _user.city : _user.locality;
          await _saveSession();
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching profile: $e");
      }
    }
  }

  /// 6. Update current user profile details in MySQL
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    String countryCode = '+91',
    String locality = '',
    String city = '',
    String state = '',
    String country = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    final cleanEmail = email.isNotEmpty ? email.trim() : _user.email;
    final url = Uri.parse('$_baseUrl/api/update-profile');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'full_name': name.trim(),
          'mobile_number': phone.trim(),
          'country_code': countryCode.trim(),
          'full_address': address.trim(),
          'locality': locality.trim(),
          'city': city.trim(),
          'state': state.trim(),
          'country': country.trim(),
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final success = response.statusCode == 200 && data['success'] == true;

      if (success) {
        final userData = data['user'] as Map<String, dynamic>?;
        if (userData != null) {
          _user.name = userData['full_name'] as String? ?? name.trim();
          _user.phone = userData['mobile_number'] as String? ?? phone.trim();
          _user.countryCode = userData['country_code'] as String? ?? countryCode.trim();
          _user.email = cleanEmail;
          _user.address = userData['full_address'] as String? ?? address.trim();
          _user.locality = userData['locality'] as String? ?? locality.trim();
          _user.city = userData['city'] as String? ?? city.trim();
          _user.state = userData['state'] as String? ?? state.trim();
          _user.country = userData['country'] as String? ?? country.trim();
        } else {
          _user.name = name.trim();
          _user.phone = phone.trim();
          _user.countryCode = countryCode.trim();
          _user.email = cleanEmail;
          _user.address = address.trim();
          _user.locality = locality.trim();
          _user.city = city.trim();
          _user.state = state.trim();
          _user.country = country.trim();
        }
        _user.location = _user.city.isNotEmpty ? _user.city : (_user.locality.isNotEmpty ? _user.locality : _user.location);
        await _saveSession();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 7. Logout current user and clear session.
  Future<void> logout() async {
    _user = UserProfile(
      userId: "",
      name: "",
      phone: "",
      countryCode: "+91",
      email: "",
      address: "",
      locality: "",
      city: "",
      state: "",
      country: "",
      location: "",
      isLoggedIn: false,
    );
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
