import 'package:flutter/material.dart';
import '../location/location_selector.dart';

class CreatePostModal extends StatefulWidget {
  final String postType; // 'job' or 'offer'
  final Function({
    required String title,
    required String subtitle,
    required String description,
    required String targetLocation,
  }) onSubmit;

  const CreatePostModal({
    super.key,
    required this.postType,
    required this.onSubmit,
  });

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedTargetLocation = "T. Nagar, Chennai";

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isJob = widget.postType == 'job';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isJob ? 'Post a New Job' : 'Create Special Offer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title Input
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: isJob
                    ? 'e.g. Graphic Designer Needed'
                    : 'e.g. Flat 30% Off Mobile Accessories',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Subtitle Input
            const Text(
              'Tagline / Subtitle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _subtitleController,
              decoration: InputDecoration(
                hintText: isJob
                    ? 'e.g. 1-2 Years Exp • Full Time'
                    : 'e.g. Valid till Sunday • Coupon: FESTIVE',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Description Input
            const Text(
              'Detailed Description',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add specifics, requirements, or offer terms...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Target Location Selector (Requirement #12)
            const Text(
              'Target Location',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            LocationSelector(
              initialValue: _selectedTargetLocation,
              onLocationSelected: (val) {
                setState(() {
                  _selectedTargetLocation = val;
                });
              },
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a title')),
                    );
                    return;
                  }
                  widget.onSubmit(
                    title: _titleController.text.trim(),
                    subtitle: _subtitleController.text.trim(),
                    description: _descController.text.trim(),
                    targetLocation: _selectedTargetLocation,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Publish to Feed',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
