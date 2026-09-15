import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController(text: 'Mani Kumar');
  final _phoneController = TextEditingController(text: '+91 98402 33421');
  final _addressController = TextEditingController(text: '14/2, Usman Road, T. Nagar, Chennai - 600017');

  bool _isFetchingAddress = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddress() async {
    if (_isFetchingAddress) return;

    setState(() {
      _isFetchingAddress = true;
    });

    try {
      final locService = Provider.of<LocationService>(context, listen: false);
      final loc = await locService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _addressController.text = "${loc.area}, ${loc.city}, ${loc.state}";
          _isFetchingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingAddress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve address. Please try again.')),
        );
      }
    }
  }

  void _clearAddress() {
    setState(() {
      _addressController.clear();
    });
  }

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.registerUser(
      name: name,
      phone: phone,
      email: authService.pendingEmail ?? 'mani.chennai@example.com',
      address: address.isNotEmpty ? address : 'T. Nagar, Chennai',
      location: 'T. Nagar, Chennai',
    );

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Color(0xFF4F46E5), size: 26),
                ),
                const SizedBox(height: 20),
                const Text(
                  'User Registration',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Complete your personal details to personalize local feed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Input
                const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone Input
                const Text('Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
                const SizedBox(height: 14),

                // Address Input (Read-only)
                const Text('Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                const SizedBox(height: 6),
                TextField(
                  controller: _addressController,
                  readOnly: true,
                  onTap: _fetchAddress,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Tap "Get Address" to fetch location...',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF4F46E5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
                const SizedBox(height: 10),

                // Address Action Buttons: Get Address & Clear
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isFetchingAddress ? null : _fetchAddress,
                        icon: _isFetchingAddress
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 16),
                        label: Text(_isFetchingAddress ? 'Fetching...' : 'Get Address'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _clearAddress,
                      icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFFEF4444)),
                      label: const Text('Clear', style: TextStyle(color: Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),

                if (_isFetchingAddress) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Retrieving current location and address details...',
                            style: TextStyle(fontSize: 11, color: Color(0xFF4338CA), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Save & Next', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
