import 'package:flutter/foundation.dart';
import '../models/target_location_model.dart';

class PostItem {
  final String postId;
  final String businessProfileId;
  final String bizName;
  final String type; // 'job', 'offer', or 'coupon'
  final String title;
  final String subtitle;
  final String description;
  final String? exp;
  final String? jobType;
  final List<String> images; // Ordered list of post images
  final String? validity;
  final String? discount;
  final String? couponCode;
  final String? badgeText; // e.g. '7d left', '6k liked', 'Expired', 'Popular'
  final String? brandLogo;
  final String? terms;
  final String timeAgo;
  final DateTime createdAt;
  final String? targetLocation;
  final List<TargetLocationModel>? targetLocationItems;
  bool isSaved;

  PostItem({
    required this.postId,
    required this.businessProfileId,
    required this.bizName,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    this.exp,
    this.jobType,
    String? image,
    List<String>? images,
    this.validity,
    this.discount,
    this.couponCode,
    this.badgeText,
    this.brandLogo,
    this.terms,
    required this.timeAgo,
    DateTime? createdAt,
    this.targetLocation,
    this.targetLocationItems,
    this.isSaved = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        images = (images != null && images.isNotEmpty)
            ? images
            : (image != null && image.isNotEmpty ? [image] : []);

  /// Backward compatibility getter for single-image references
  String? get image => images.isNotEmpty ? images.first : null;

  /// Formats the post creation time for bottom-right corner display (e.g. 10:35 AM)
  String get formattedPostTime {
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final ampm = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}

class PostService extends ChangeNotifier {
  final List<PostItem> _feedPosts = [
    // --- COUPON POSTS (Matching reference design) ---
    PostItem(
      postId: "C001",
      businessProfileId: "BP001",
      bizName: "ABC Dental Clinic",
      type: "coupon",
      title: "Flat 50% Off",
      subtitle: "Complete Dental Health Checkup & X-Ray",
      description: "Get 50% flat discount on complete oral examinations, cleaning, and digital dental X-Rays. Valid for first-time visitors and family consultations.",
      discount: "Flat 50% Off",
      couponCode: "DENTAL50",
      badgeText: "7d left",
      validity: "Valid for 7 days",
      terms: "1. Applicable only on appointment bookings.\n2. One coupon per patient.\n3. Cannot be clubbed with other packages.",
      images: [
        "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=600&q=80",
      ],
      brandLogo: "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=150&q=80",
      timeAgo: "2 hours ago",
      createdAt: DateTime(2026, 9, 16, 9, 0),
      targetLocation: "Tirunelveli",
      isSaved: false,
    ),
    PostItem(
      postId: "C002",
      businessProfileId: "BP002",
      bizName: "Tech Solutions",
      type: "coupon",
      title: "Only for ₹299",
      subtitle: "Deep Bass Earbuds | Free Shipping",
      description: "Experience ultra high-definition audio with premium wireless earbuds featuring active noise cancellation and 30-hour battery life. Includes fast charging case and 1-year replacement warranty.",
      discount: "Only for ₹299",
      couponCode: "TECPOD299",
      badgeText: "6k liked",
      validity: "Limited Stock Deal",
      terms: "1. Available on prepaid and COD orders.\n2. Standard delivery within 48 hours.\n3. 7-day replacement guarantee.",
      images: [
        "https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1572536147248-ac59a8abfa4b?auto=format&fit=crop&w=600&q=80",
      ],
      brandLogo: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=150&q=80",
      timeAgo: "3 hours ago",
      createdAt: DateTime(2026, 9, 16, 10, 15),
      targetLocation: "Madurai",
      isSaved: true,
    ),
    PostItem(
      postId: "C003",
      businessProfileId: "BP003",
      bizName: "Sri Lakshmi Electricals",
      type: "coupon",
      title: "Flat 70% off",
      subtitle: "on Leaf Earbuds, Neckbands, Smartwatches",
      description: "Massive festive clearance sale on certified audio gear, wireless neckbands, and smart fitness trackers. Claim your instant digital discount code today.",
      discount: "Flat 70% off",
      couponCode: "LEAF70",
      badgeText: "Expired",
      validity: "Expired yesterday",
      terms: "1. Valid on select models only.\n2. Maximum discount capped at ₹1,500 per bill.\n3. Present QR / Code in-store.",
      images: [
        "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=600&q=80",
      ],
      brandLogo: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=150&q=80",
      timeAgo: "1 day ago",
      createdAt: DateTime(2026, 9, 15, 12, 0),
      targetLocation: "Nagercoil",
      isSaved: false,
    ),
    PostItem(
      postId: "C004",
      businessProfileId: "BP002",
      bizName: "Tech Solutions",
      type: "coupon",
      title: "5% cashback",
      subtitle: "On select gift card purchase on Google Pay",
      description: "Earn instant 5% cashback rewards credited to your linked UPI account on all eligible electronic and software digital gift card vouchers.",
      discount: "5% cashback",
      couponCode: "CASH5BACK",
      badgeText: "Active",
      validity: "Valid till end of month",
      terms: "1. Minimum transaction of ₹500 required.\n2. Cashback processed within 24 hours.\n3. Applicable once per user.",
      images: [
        "https://images.unsplash.com/photo-1559526324-4b87b5e36e44?auto=format&fit=crop&w=600&q=80",
      ],
      brandLogo: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=150&q=80",
      timeAgo: "4 hours ago",
      createdAt: DateTime(2026, 9, 16, 14, 0),
      targetLocation: "Madurai",
      isSaved: false,
    ),
    PostItem(
      postId: "C005",
      businessProfileId: "BP001",
      bizName: "ABC Dental Clinic",
      type: "coupon",
      title: "Get 8 Slices",
      subtitle: "of Large Pizza @ ₹499 + ₹50 Cashback",
      description: "Partner meal feast coupon! Enjoy a gourmet 8-slice large farm fresh pizza with complimentary garlic breadsticks and garlic dip.",
      discount: "Get 8 Slices",
      couponCode: "PIZZA499",
      badgeText: "Expired",
      validity: "Expired",
      terms: "1. Valid for dine-in and takeaway orders.\n2. GST applicable on invoice.\n3. Not valid during blackout dates.",
      images: [
        "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=600&q=80",
      ],
      brandLogo: "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=150&q=80",
      timeAgo: "2 days ago",
      createdAt: DateTime(2026, 9, 14, 18, 30),
      targetLocation: "Tirunelveli",
      isSaved: false,
    ),
    PostItem(
      postId: "C006",
      businessProfileId: "BP003",
      bizName: "Sri Lakshmi Electricals",
      type: "coupon",
      title: "Flat ₹400 Off",
      subtitle: "on Luxury Gift Sets & Home Appliance Care",
      description: "Special seasonal discount voucher. Get flat ₹400 off on home electrical appliance maintenance kits, luxury grooming sets, and smart LED fixture bundles.",
      discount: "Flat ₹400 Off",
      couponCode: "LUX400",
      badgeText: "Expired",
      validity: "Expired",
      terms: "1. Minimum bill value ₹1,200.\n2. Valid at store and online booking.\n3. Limited to 1 voucher per customer.",
      images: [
        "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80",
      ],
      brandLogo: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=150&q=80",
      timeAgo: "3 days ago",
      createdAt: DateTime(2026, 9, 13, 11, 0),
      targetLocation: "Nagercoil",
      isSaved: false,
    ),

    // --- STANDARD FEED POSTS (Jobs & Offers) ---
    PostItem(
      postId: "P001",
      businessProfileId: "BP001",
      bizName: "ABC Dental Clinic",
      type: "offer",
      title: "Quality Dental Care & Regular Checkups",
      subtitle: "ABC Dental Clinic • Tirunelveli",
      description: "We provide quality dental care and regular dental checkups. Book your appointment today.",
      discount: "CHECKUP DEAL",
      validity: "Booking Open",
      images: [
        "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=600&q=80",
      ],
      timeAgo: "1 hour ago",
      createdAt: DateTime(2026, 9, 16, 10, 35),
      targetLocation: "Tirunelveli",
      isSaved: false,
    ),
    PostItem(
      postId: "P002",
      businessProfileId: "BP002",
      bizName: "Tech Solutions",
      type: "job",
      title: "Professional Software & IT Solutions",
      subtitle: "Tech Solutions • Madurai",
      description: "We provide professional software development and IT solutions for businesses.",
      exp: "Open Positions",
      jobType: "Full Time",
      timeAgo: "2 hours ago",
      createdAt: DateTime(2026, 9, 16, 11, 45),
      targetLocation: "Madurai",
      images: [],
      isSaved: false,
    ),
    PostItem(
      postId: "P003",
      businessProfileId: "BP003",
      bizName: "Sri Lakshmi Electricals",
      type: "offer",
      title: "Reliable Electrical Installation & Repair",
      subtitle: "Sri Lakshmi Electricals • Nagercoil",
      description: "We provide reliable electrical installation, repair, and maintenance services.",
      discount: "SERVICE DEAL",
      validity: "Active Service",
      images: [
        "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80",
      ],
      timeAgo: "3 hours ago",
      createdAt: DateTime(2026, 9, 16, 14, 15),
      targetLocation: "Nagercoil",
      isSaved: false,
    ),
  ];

  String _activeFilter = 'all'; // 'all', 'jobs', 'offers', 'coupons', 'followed'

  String get activeFilter => _activeFilter;
  List<PostItem> get allPosts => List.unmodifiable(_feedPosts);
  List<PostItem> get savedPosts => _feedPosts.where((p) => p.isSaved).toList();

  /// Retrieve all coupons specifically
  List<PostItem> get allCoupons =>
      _feedPosts.where((p) => p.type == 'coupon').toList();

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  /// Get filtered feed posts based on active filter and followed business profile IDs
  List<PostItem> getFilteredPosts(List<String> followedProfileIds) {
    return _feedPosts.where((post) {
      if (_activeFilter == 'all') return post.type != 'coupon'; // Keep feed focused on jobs & offers by default
      if (_activeFilter == 'jobs') return post.type == 'job';
      if (_activeFilter == 'offers') return post.type == 'offer';
      if (_activeFilter == 'coupons') return post.type == 'coupon';
      if (_activeFilter == 'followed') {
        return followedProfileIds.contains(post.businessProfileId);
      }
      return true;
    }).toList();
  }

  /// Purpose: Save or unsave (bookmark) a post or coupon.
  void toggleSavePost(String postId) {
    final index = _feedPosts.indexWhere((p) => p.postId == postId);
    if (index != -1) {
      _feedPosts[index].isSaved = !_feedPosts[index].isSaved;
      notifyListeners();
    }
  }

  /// Purpose: Create and publish a new post/coupon from a business profile.
  Future<PostItem> createPost({
    required String businessProfileId,
    required String bizName,
    required String type, // 'job', 'offer', 'coupon'
    required String title,
    required String subtitle,
    required String description,
    String? image,
    List<String>? images,
    String? discount,
    String? couponCode,
    String? validity,
    String? badgeText,
    String? brandLogo,
    String? terms,
    String? targetLocation,
    List<TargetLocationModel>? targetLocationItems,
  }) async {
    final selectedImages = (images != null && images.isNotEmpty)
        ? images
        : (image != null && image.isNotEmpty ? [image] : <String>[]);

    final newPost = PostItem(
      postId: type == 'coupon'
          ? "C${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}"
          : DateTime.now().millisecondsSinceEpoch.toString(),
      businessProfileId: businessProfileId,
      bizName: bizName,
      type: type,
      title: title,
      subtitle: subtitle,
      description: description,
      exp: type == 'job' ? "Open" : null,
      jobType: type == 'job' ? "Full Time" : null,
      timeAgo: "Just now",
      images: selectedImages,
      validity: validity ?? (type == 'offer' ? "Active now" : (type == 'coupon' ? "Active deal" : null)),
      discount: discount ?? (type == 'offer' ? "SPECIAL DEAL" : (type == 'coupon' ? title : null)),
      couponCode: couponCode ?? (type == 'coupon' ? "DEAL${DateTime.now().millisecond}" : null),
      badgeText: badgeText ?? (type == 'coupon' ? "Active" : null),
      brandLogo: brandLogo,
      terms: terms ?? (type == 'coupon' ? "1. Present this coupon in store or enter code during booking." : null),
      targetLocation: targetLocation,
      targetLocationItems: targetLocationItems,
      isSaved: false,
    );

    _feedPosts.insert(0, newPost);
    notifyListeners();
    return newPost;
  }

  /// Purpose: Delete a post by postId (only if caller owns the business profile)
  bool deletePost(String postId, {String? callerBusinessProfileId}) {
    final index = _feedPosts.indexWhere((p) => p.postId == postId);
    if (index != -1) {
      if (callerBusinessProfileId != null &&
          _feedPosts[index].businessProfileId != callerBusinessProfileId) {
        return false;
      }
      _feedPosts.removeAt(index);
      notifyListeners();
      return true;
    }
    return false;
  }

  PostItem? getPostById(String postId) {
    try {
      return _feedPosts.firstWhere((p) => p.postId == postId);
    } catch (_) {
      return null;
    }
  }

  PostItem? getCouponById(String couponId) {
    return getPostById(couponId);
  }
}
