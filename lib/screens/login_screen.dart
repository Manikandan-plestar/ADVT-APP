import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController(text: '123456');

  bool _isValidEmail = false;
  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final valid = email.isNotEmpty && emailRegex.hasMatch(email);
    if (_isValidEmail != valid) {
      setState(() {
        _isValidEmail = valid;
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    if (!_isValidEmail || _isSendingOtp) return;

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.sendOtp(email);

    if (mounted && success) {
      setState(() {
        _isSendingOtp = false;
        _isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully to $email'),
          backgroundColor: const Color(0xFF4F46E5),
        ),
      );
    } else if (mounted) {
      setState(() {
        _isSendingOtp = false;
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
  }

  void _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _isVerifyingOtp) return;

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.verifyOtp(otp);

    if (!mounted) return;

    setState(() {
      _isVerifyingOtp = false;
    });

    if (success) {
      Navigator.pushReplacementNamed(context, '/register');
    } else {
      setState(() {
        _errorMessage = 'Invalid or expired OTP code. Use 123456';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF4F46E5), size: 26),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to ADVT APP',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your email address to receive a verification OTP.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 32),

                // Email Address Field
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isOtpSent,
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF9CA3AF)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Send OTP Button directly below Email Address field
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isValidEmail && !_isSendingOtp && !_isOtpSent)
                        ? _handleSendOtp
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      disabledBackgroundColor: const Color(0xFFC7D2FE),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _isOtpSent ? 'OTP Sent' : 'Send OTP',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                // Inline OTP Verification UI (Appears below Send OTP after sending)
                if (_isOtpSent) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'OTP Code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter 6-digit verification code sent to your email (Demo: 123456)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: '123456',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Verify Button directly below OTP field
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), // Emerald green for verify
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isVerifyingOtp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
