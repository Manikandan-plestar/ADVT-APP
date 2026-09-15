import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/business_service.dart';

class EditBusinessScreen extends StatefulWidget {
  final String businessProfileId;

  const EditBusinessScreen({super.key, required this.businessProfileId});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  late TextEditingController _nameController;
  late TextEditingController _catController;
  late TextEditingController _locController;
  late TextEditingController _aboutController;

  @override
  void initState() {
    super.initState();
    final biz = Provider.of<BusinessService>(context, listen: false).getBusinessById(widget.businessProfileId);
    _nameController = TextEditingController(text: biz?.name ?? '');
    _catController = TextEditingController(text: biz?.category ?? '');
    _locController = TextEditingController(text: biz?.location ?? '');
    _aboutController = TextEditingController(text: biz?.about ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _catController.dispose();
    _locController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final bizService = Provider.of<BusinessService>(context, listen: false);
    bizService.updateBusinessProfile(
      businessProfileId: widget.businessProfileId,
      name: _nameController.text.trim(),
      category: _catController.text.trim(),
      location: _locController.text.trim(),
      about: _aboutController.text.trim(),
    );
    Navigator.pop(context);
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
          'Edit Business Profile',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Business Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(controller: _nameController, decoration: _inputDecoration()),
            const SizedBox(height: 14),

            const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(controller: _catController, decoration: _inputDecoration()),
            const SizedBox(height: 14),

            const Text('Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(controller: _locController, decoration: _inputDecoration()),
            const SizedBox(height: 14),

            const Text('About Business', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(controller: _aboutController, maxLines: 3, decoration: _inputDecoration()),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Update Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
    );
  }
}
