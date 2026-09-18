import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/target_location_model.dart';
import '../../services/device_image_picker_service.dart';
import '../../services/target_location_service.dart';
import 'target_location_picker_modal.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class CreatePostModal extends StatefulWidget {
  final String postType; // 'job', 'offer', or 'coupon'
  final Function({
    required String title,
    required String subtitle,
    required String description,
    required String targetLocation,
    String? couponCode,
    List<TargetLocationModel>? targetLocations,
    List<String>? images,
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
  final _couponCodeController = TextEditingController();
  final _descController = TextEditingController();

  // Selected post images from local device
  List<String> _selectedImages = [];
  bool _isProcessingImages = false;

  // Default initial selected target locations
  List<TargetLocationModel> _selectedTargetLocations = [
    TargetLocationService.defaultLocations.firstWhere(
      (loc) => loc.placeId == 'city_tirunelveli',
      orElse: () => TargetLocationService.defaultLocations.first,
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _couponCodeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromDevice() async {
    setState(() => _isProcessingImages = true);
    try {
      final result = await DeviceImagePickerService.pickImagesFromGallery(
        currentSelected: _selectedImages,
        maxLimit: 6,
      );

      if (mounted) {
        setState(() {
          _selectedImages = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open device gallery.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImages = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TargetLocationPickerModal(
        initialSelectedLocations: _selectedTargetLocations,
        onApply: (updatedLocations) {
          setState(() {
            _selectedTargetLocations = updatedLocations;
          });
        },
      ),
    );
  }

  void _removeLocation(TargetLocationModel loc) {
    setState(() {
      _selectedTargetLocations.removeWhere((e) => e.placeId == loc.placeId);
    });
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'country':
        return const Color(0xFF4338CA);
      case 'state':
        return const Color(0xFF7C3AED);
      case 'city':
      case 'district':
        return const Color(0xFF2563EB);
      case 'locality':
      case 'sublocality':
      case 'area':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isJob = widget.postType == 'job';
    final isCoupon = widget.postType == 'coupon';

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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isJob
                      ? 'Post a New Job'
                      : (isCoupon ? 'Publish a Coupon' : 'Create Special Offer'),
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
            Text(
              isCoupon ? 'Offer / Discount Headline' : 'Title',
              style: const TextStyle(
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
                    : (isCoupon
                        ? 'e.g. Flat 50% Off / Only for ₹299'
                        : 'e.g. Flat 30% Off Mobile Accessories'),
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
            Text(
              isCoupon ? 'Product / Deal Tagline' : 'Tagline / Subtitle',
              style: const TextStyle(
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
                    : (isCoupon
                        ? 'e.g. Deep Bass Earbuds & Free Shipping'
                        : 'e.g. Valid till Sunday • Coupon: FESTIVE'),
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

            // Coupon Code Input (Placed below Product / Deal Tagline, uppercase only)
            if (isCoupon) ...[
              const Text(
                'Coupon Code',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _couponCodeController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. SAVE50 / FESTIVE2026',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: Color(0xFF4F46E5),
                  ),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Description Input
            Text(
              isCoupon ? 'Description & Terms' : 'Detailed Description',
              style: const TextStyle(
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
                hintText: isCoupon
                    ? 'Add coupon specifics, validity terms, or redemption steps...'
                    : 'Add specifics, requirements, or offer terms...',
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
            const SizedBox(height: 16),

            // ==========================================
            // 1. BUSINESS POST IMAGES (Positioned ABOVE Target Location)
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Post Images',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedImages.isEmpty ? '(Optional • Max 6)' : '(${_selectedImages.length}/6 selected)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _isProcessingImages ? null : _pickImagesFromDevice,
                  child: Text(
                    _selectedImages.isEmpty ? '+ Add Images' : '+ Edit Images',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _isProcessingImages ? Colors.grey : const Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Image Selection / Previews Container
            if (_selectedImages.isEmpty)
              InkWell(
                onTap: _isProcessingImages ? null : _pickImagesFromDevice,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _isProcessingImages
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.add_photo_alternate_rounded, size: 20, color: Color(0xFF4F46E5)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select images from device',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Will cycle automatically in feed every 5 seconds',
                                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              )
            else
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + (_selectedImages.length < 6 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    // Add more button tile at the end
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _isProcessingImages ? null : _pickImagesFromDevice,
                        child: Container(
                          width: 80,
                          height: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF4F46E5), size: 22),
                              SizedBox(height: 4),
                              Text(
                                'Add More',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final imagePath = _selectedImages[index];

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 80,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: _buildPreviewThumbnail(imagePath),
                          ),
                        ),
                        // Remove X badge button
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                        // Image index indicator
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // ==========================================
            // 2. TARGET LOCATION (Positioned BELOW Post Images)
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Target Location',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                GestureDetector(
                  onTap: _openLocationPicker,
                  child: Text(
                    _selectedTargetLocations.isEmpty ? '+ Add Location' : '+ Add / Edit',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Target Location Chips Container
            InkWell(
              onTap: _openLocationPicker,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _selectedTargetLocations.isEmpty
                    ? Row(
                        children: const [
                          Icon(Icons.add_location_alt_outlined, size: 18, color: Color(0xFF9CA3AF)),
                          SizedBox(width: 8),
                          Text(
                            'Tap to select target audience locations...',
                            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._selectedTargetLocations.map((loc) {
                            final color = _getTypeColor(loc.type);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withOpacity(0.35)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on_rounded, size: 13, color: color),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeLocation(loc),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: color.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Quick add chip button
                          GestureDetector(
                            onTap: _openLocationPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 14, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Add Area',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 22),

            // Publish Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessingImages
                    ? null
                    : () {
                        if (_titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a title')),
                          );
                          return;
                        }

                        if (_selectedTargetLocations.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least one target location')),
                          );
                          return;
                        }

                        final locationSummary = _selectedTargetLocations.map((e) => e.name).join(', ');

                        widget.onSubmit(
                          title: _titleController.text.trim(),
                          subtitle: _subtitleController.text.trim(),
                          description: _descController.text.trim(),
                          couponCode: isCoupon && _couponCodeController.text.trim().isNotEmpty
                              ? _couponCodeController.text.trim().toUpperCase()
                              : null,
                          targetLocation: locationSummary,
                          targetLocations: _selectedTargetLocations,
                          images: _selectedImages,
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

  Widget _buildPreviewThumbnail(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return Image.network(
        pathOrUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, size: 24, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    final file = File(pathOrUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, size: 24, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.broken_image_rounded, size: 24, color: Color(0xFF9CA3AF)),
    );
  }
}
