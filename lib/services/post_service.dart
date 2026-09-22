import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import '../models/target_location_model.dart';
import '../utils/text_utils.dart';

class PostItem {
  final String postId;
  final int? numericPostId;
  final String businessProfileId;
  final int? numericBusinessId;
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
    this.numericPostId,
    required this.businessProfileId,
    this.numericBusinessId,
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

  /// Display presentation getters with title capitalization
  String get displayTitle => TextUtils.capitalizeWords(title);
  String get displayBizName => TextUtils.capitalizeWords(bizName);
  String get displaySubtitle => TextUtils.capitalizeWords(subtitle);
  String get displayLocation => TextUtils.capitalizeWords(targetLocation ?? '');

  /// Formats the post creation time for bottom-right corner display (e.g. 10:35 AM)
  String get formattedPostTime {
    final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
    final minute = createdAt.minute.toString().padLeft(2, '0');
    final ampm = createdAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  factory PostItem.fromJson(Map<String, dynamic> json) {
    final rawPostId = json['post_id'] ?? json['postId'] ?? 0;
    final int? numPostId = rawPostId is int
        ? rawPostId
        : int.tryParse(rawPostId.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    final postType = (json['post_type'] ?? json['type'] ?? 'offer').toString().toLowerCase();
    final prefix = postType == 'coupon' ? 'C' : 'P';
    final formattedPostId = json['postId'] as String? ??
        (numPostId != null ? '$prefix${numPostId.toString().padLeft(3, '0')}' : rawPostId.toString());

    final rawBizId = json['business_id'] ?? json['businessProfileId'] ?? 0;
    final int? numBizId = rawBizId is int
        ? rawBizId
        : int.tryParse(rawBizId.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    final formattedBizId = json['businessProfileId'] as String? ??
        (numBizId != null ? 'BP${numBizId.toString().padLeft(3, '0')}' : rawBizId.toString());

    List<String> imgList = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        imgList = (json['images'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      } else if (json['images'] is String) {
        try {
          final decoded = jsonDecode(json['images'] as String);
          if (decoded is List) {
            imgList = decoded.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
          }
        } catch (_) {
          if ((json['images'] as String).isNotEmpty) {
            imgList = [json['images'] as String];
          }
        }
      }
    }

    List<TargetLocationModel>? targetLocItems;
    final rawLocs = json['target_locations_json'] ?? json['targetLocationItems'] ?? json['target_locations'];
    if (rawLocs != null) {
      if (rawLocs is List) {
        targetLocItems = rawLocs
            .map((item) => TargetLocationModel.fromMap(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (rawLocs is String && rawLocs.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawLocs);
          if (decoded is List) {
            targetLocItems = decoded
                .map((item) => TargetLocationModel.fromMap(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map)))
                .toList();
          }
        } catch (_) {}
      }
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (json['created_at'] != null || json['createdAt'] != null) {
      try {
        parsedCreatedAt = DateTime.parse((json['created_at'] ?? json['createdAt']).toString());
      } catch (_) {}
    }

    return PostItem(
      postId: formattedPostId,
      numericPostId: numPostId,
      businessProfileId: formattedBizId,
      numericBusinessId: numBizId,
      bizName: json['bizName'] ?? json['business_name'] ?? '',
      type: postType,
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      exp: json['exp'] ?? json['experience'],
      jobType: json['jobType'] ?? json['job_type'],
      images: imgList,
      validity: json['validity'],
      discount: json['discount'] ?? json['discount_label'],
      couponCode: json['couponCode'] ?? json['coupon_code'],
      badgeText: json['badgeText'] ?? json['badge_text'],
      brandLogo: json['brandLogo'] ?? json['brand_logo'] ?? json['business_profile_image'],
      terms: json['terms'],
      timeAgo: json['timeAgo'] ?? 'Just now',
      createdAt: parsedCreatedAt,
      targetLocation: json['targetLocation'] ?? json['target_location'],
      targetLocationItems: targetLocItems,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'numericPostId': numericPostId,
      'businessProfileId': businessProfileId,
      'numericBusinessId': numericBusinessId,
      'bizName': bizName,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'exp': exp,
      'jobType': jobType,
      'images': images,
      'validity': validity,
      'discount': discount,
      'couponCode': couponCode,
      'badgeText': badgeText,
      'brandLogo': brandLogo,
      'terms': terms,
      'timeAgo': timeAgo,
      'createdAt': createdAt.toIso8601String(),
      'targetLocation': targetLocation,
      'targetLocationItems': targetLocationItems?.map((e) => e.toMap()).toList(),
      'isSaved': isSaved,
    };
  }
}

class PostService extends ChangeNotifier {
  final List<PostItem> _feedPosts = [];
  bool _isLoading = false;
  String _activeFilter = 'all'; // 'all', 'jobs', 'offers', 'coupons', 'followed'

  // Base URL configuration (delegated to unified ApiClient)
  String get _baseUrl => ApiClient().baseUrl;
  String get baseUrl => ApiClient().baseUrl;
  set baseUrl(String url) {
    ApiClient().setBaseUrl(url);
    notifyListeners();
  }

  bool get isLoading => _isLoading;
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
      if (_activeFilter == 'all') return post.type != 'coupon'; // Keep home feed focused on jobs & offers by default
      if (_activeFilter == 'jobs') return post.type == 'job';
      if (_activeFilter == 'offers') return post.type == 'offer';
      if (_activeFilter == 'coupons') return post.type == 'coupon';
      if (_activeFilter == 'followed') {
        return followedProfileIds.contains(post.businessProfileId);
      }
      return true;
    }).toList();
  }

  /// Purpose: Fetch live posts from MySQL backend with optional filters
  Future<List<PostItem>> fetchPosts({
    String? location,
    String? postType,
    String? businessId,
    String? userId,
    String? search,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (location != null && location.isNotEmpty && location.toLowerCase() != 'all') {
        queryParams['location'] = location.trim();
      }
      if (postType != null && postType.isNotEmpty && postType.toLowerCase() != 'all') {
        queryParams['type'] = postType.trim();
      }
      if (businessId != null && businessId.isNotEmpty) {
        queryParams['business_id'] = businessId.trim();
      }
      if (userId != null && userId.isNotEmpty) {
        queryParams['user_id'] = userId.trim();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final uri = Uri.parse('$_baseUrl/api/posts').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['posts'] is List) {
          final List list = data['posts'] as List;
          final fetchedPosts = list.map((item) => PostItem.fromJson(item as Map<String, dynamic>)).toList();

          if (businessId != null && businessId.isNotEmpty) {
            // Update posts for this specific business profile
            _feedPosts.removeWhere((p) => p.businessProfileId == businessId);
            _feedPosts.addAll(fetchedPosts);
          } else if (postType == 'coupon') {
            // Update coupon posts
            _feedPosts.removeWhere((p) => p.type == 'coupon');
            _feedPosts.addAll(fetchedPosts);
          } else {
            // Full feed update: replace with fresh server posts while preserving isSaved bookmark states
            final savedIds = _feedPosts.where((p) => p.isSaved).map((p) => p.postId).toSet();
            for (final p in fetchedPosts) {
              if (savedIds.contains(p.postId)) {
                p.isSaved = true;
              }
            }
            _feedPosts.clear();
            _feedPosts.addAll(fetchedPosts);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PostService] Error fetching posts: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _feedPosts;
  }

  /// Purpose: Save or unsave (bookmark) a post or coupon.
  void toggleSavePost(String postId) {
    final index = _feedPosts.indexWhere((p) => p.postId == postId);
    if (index != -1) {
      _feedPosts[index].isSaved = !_feedPosts[index].isSaved;
      notifyListeners();
    }
  }

  /// Purpose: Create and publish a new post/coupon from a business profile to MySQL backend.
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
    String? authToken,
    String? userId,
    String? userEmail,
  }) async {
    final selectedImages = (images != null && images.isNotEmpty)
        ? images
        : (image != null && image.isNotEmpty ? [image] : <String>[]);

    final cleanBizId = businessProfileId.replaceAll(RegExp(r'[^0-9]'), '');

    final payload = {
      'business_id': cleanBizId.isNotEmpty ? int.parse(cleanBizId) : businessProfileId,
      'type': type,
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'description': description.trim(),
      'coupon_code': couponCode?.trim(),
      'discount': discount ?? (type == 'offer' ? "SPECIAL DEAL" : (type == 'coupon' ? title : null)),
      'job_type': type == 'job' ? "Full Time" : null,
      'exp': type == 'job' ? "Open" : null,
      'validity': validity ?? (type == 'offer' ? "Active now" : (type == 'coupon' ? "Active deal" : null)),
      'badge_text': badgeText ?? (type == 'coupon' ? "Active" : null),
      'terms': terms ?? (type == 'coupon' ? "1. Present this coupon in store or enter code during booking." : null),
      'target_location': targetLocation ?? 'Tamil Nadu',
      'target_locations': targetLocationItems?.map((e) => e.toMap()).toList(),
      'images': selectedImages,
      'brand_logo': brandLogo,
    };

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      if (userId != null && userId.isNotEmpty) 'x-user-id': userId.replaceAll(RegExp(r'[^0-9]'), ''),
      if (userEmail != null && userEmail.isNotEmpty) 'x-user-email': userEmail.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/posts'),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['post'] != null) {
          final serverPost = PostItem.fromJson(data['post'] as Map<String, dynamic>);
          _feedPosts.insert(0, serverPost);
          notifyListeners();
          return serverPost;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PostService] Error publishing post to backend: $e');
      }
    }

    // Fallback local creation if offline or pending sync
    final fallbackPost = PostItem(
      postId: type == 'coupon'
          ? "C${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}"
          : "P${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
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

    _feedPosts.insert(0, fallbackPost);
    notifyListeners();
    return fallbackPost;
  }

  /// Purpose: Delete a post by postId (Ownership validated on backend)
  Future<bool> deletePost(
    String postId, {
    String? callerBusinessProfileId,
    String? authToken,
    String? userId,
    String? userEmail,
  }) async {
    final cleanPostId = postId.replaceAll(RegExp(r'[^0-9]'), '');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      if (userId != null && userId.isNotEmpty) 'x-user-id': userId.replaceAll(RegExp(r'[^0-9]'), ''),
      if (userEmail != null && userEmail.isNotEmpty) 'x-user-email': userEmail.trim(),
    };

    bool serverSuccess = false;
    if (cleanPostId.isNotEmpty) {
      try {
        final response = await http.delete(
          Uri.parse('$_baseUrl/api/posts/$cleanPostId'),
          headers: headers,
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          serverSuccess = true;
        }
      } catch (e) {
        if (kDebugMode) {
          print('[PostService] Error deleting post from backend: $e');
        }
      }
    }

    final index = _feedPosts.indexWhere((p) => p.postId == postId || p.numericPostId?.toString() == cleanPostId);
    if (index != -1) {
      if (callerBusinessProfileId != null &&
          _feedPosts[index].businessProfileId != callerBusinessProfileId) {
        return false;
      }
      _feedPosts.removeAt(index);
      notifyListeners();
      return true;
    }

    return serverSuccess;
  }

  PostItem? getPostById(String postId) {
    try {
      final clean = postId.replaceAll(RegExp(r'[^0-9]'), '');
      return _feedPosts.firstWhere((p) => p.postId == postId || (clean.isNotEmpty && p.numericPostId?.toString() == clean));
    } catch (_) {
      return null;
    }
  }

  PostItem? getCouponById(String couponId) {
    return getPostById(couponId);
  }
}
