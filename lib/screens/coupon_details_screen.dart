import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/post_service.dart';
import '../services/business_service.dart';
import '../widgets/business/cycling_post_image.dart';
import '../widgets/detail/route_map.dart';

class CouponDetailsScreen extends StatefulWidget {
  final String postId;

  const CouponDetailsScreen({super.key, required this.postId});

  @override
  State<CouponDetailsScreen> createState() => _CouponDetailsScreenState();
}

class _CouponDetailsScreenState extends State<CouponDetailsScreen> {
  bool _showRouteMap = false;
  bool _isCopied = false;

  void _copyCouponCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Coupon code "$code" copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final postService = Provider.of<PostService>(context);
    final bizService = Provider.of<BusinessService>(context);

    final coupon = postService.getCouponById(widget.postId);
    if (coupon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Coupon Details')),
        body: const Center(child: Text('Coupon not found')),
      );
    }

    // Identify the exact Business Profile via unique BusinessProfileId
    final biz = bizService.getBusinessById(coupon.businessProfileId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Coupon Details',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        actions: [
          IconButton(
            onPressed: () => postService.toggleSavePost(coupon.postId),
            icon: Icon(
              coupon.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: coupon.isSaved ? const Color(0xFF4F46E5) : const Color(0xFF4B5563),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Business / Shop Header
            if (biz != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x04000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/business-details',
                                arguments: biz.businessProfileId,
                              );
                            },
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    biz.image,
                                    width: 46,
                                    height: 46,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 46,
                                      height: 46,
                                      color: const Color(0xFFEEF2FF),
                                      child: const Icon(Icons.store_rounded, color: Color(0xFF4F46E5)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              biz.name,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF111827),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF3B82F6)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        biz.category,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => bizService.toggleFollow(biz.businessProfileId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: biz.isFollowed ? const Color(0xFFF3F4F6) : const Color(0xFFEEF2FF),
                            foregroundColor: biz.isFollowed ? const Color(0xFF374151) : const Color(0xFF4F46E5),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            biz.isFollowed ? '✓ Following' : '+ Follow',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  biz.location,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showRouteMap = !_showRouteMap;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.navigation_rounded, size: 12),
                          label: const Text('Route', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (_showRouteMap) ...[
              const SizedBox(height: 14),
              const RouteMapWidget(),
            ],

            const SizedBox(height: 16),

            // Coupon Main Card Details
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Discount Badge & Validity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          coupon.discount ?? 'COUPON DEAL',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          coupon.validity ?? 'Active Voucher',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Coupon Title & Subtitle
                  Text(
                    coupon.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coupon.subtitle,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 16),

                  // Coupon Image Carousel / Banner
                  if (coupon.images.isNotEmpty) ...[
                    CyclingPostImage(
                      images: coupon.images,
                      height: 180,
                      borderRadius: BorderRadius.circular(16),
                      interval: const Duration(seconds: 5),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Coupon Code Ticket Voucher Box
                  if (coupon.couponCode != null && coupon.couponCode!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBBF7D0), style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PROMO CODE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Color(0xFF166534),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                coupon.couponCode!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _copyCouponCode(coupon.couponCode!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _isCopied ? const Color(0xFF15803D) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                                        size: 13,
                                        color: _isCopied ? Colors.white : const Color(0xFF15803D),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isCopied ? 'Copied' : 'Copy',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _isCopied ? Colors.white : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Show this code at store checkout or enter during online purchase',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF166534)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 14),

                  // Full Description
                  const Text(
                    'Coupon Details & Perks',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coupon.description,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.5),
                  ),
                  const SizedBox(height: 16),

                  // Terms and conditions
                  if (coupon.terms != null && coupon.terms!.isNotEmpty) ...[
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827), letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      coupon.terms!,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), height: 1.45),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Association Metadata (Unique Identifiers)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Business ID: ${coupon.businessProfileId}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Coupon ID: ${coupon.postId}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (coupon.couponCode != null) {
                              _copyCouponCode(coupon.couponCode!);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Voucher claimed successfully! Valid for immediate redemption.'),
                                backgroundColor: Color(0xFF4F46E5),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5), // Indigo
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Claim / Redeem Coupon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => postService.toggleSavePost(coupon.postId),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: Icon(
                          coupon.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: coupon.isSaved ? const Color(0xFF4F46E5) : const Color(0xFF374151),
                          size: 18,
                        ),
                        label: Text(
                          coupon.isSaved ? 'Saved' : 'Save',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: coupon.isSaved ? const Color(0xFF4F46E5) : const Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
