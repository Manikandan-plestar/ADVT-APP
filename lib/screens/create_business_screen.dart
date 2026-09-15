import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';

class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  final _nameController = TextEditingController();
  final _catController = TextEditingController();
  final _locController = TextEditingController();
  final _aboutController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _catController.dispose();
    _locController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _submitNewBusiness() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter business name')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final bizService = Provider.of<BusinessService>(context, listen: false);

    final newBiz = await bizService.createBusinessProfile(
      ownerUserId: authService.currentUser.userId,
      name: name,
      category: _catController.text.trim().isNotEmpty ? _catController.text.trim() : 'General Store',
      location: _locController.text.trim().isNotEmpty ? _locController.text.trim() : 'Chennai',
      about: _aboutController.text.trim(),
    );

    if (mounted) {
      bizService.setActiveBusiness(newBiz.businessProfileId);
      Navigator.pushReplacementNamed(context, '/biz-manage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Register Business',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business / Store Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('e.g. Saffron Cloud Kitchen'),
            ),
            const SizedBox(height: 14),

            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: _catController,
              decoration: _inputDecoration('e.g. Restaurant & Cafe'),
            ),
            const SizedBox(height: 14),

            const Text('Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: _locController,
              decoration: _inputDecoration('e.g. Velachery, Chennai'),
            ),
            const SizedBox(height: 14),

            const Text('About Business', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: _aboutController,
              maxLines: 3,
              decoration: _inputDecoration('Describe your services...'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitNewBusiness,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Create & Save Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    );
  }
}
