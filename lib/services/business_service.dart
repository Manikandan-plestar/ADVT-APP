import 'package:flutter/foundation.dart';
import 'post_service.dart';

class BusinessProfile {
  final String businessProfileId; // Unique ID (e.g. BP001), NOT phone number!
  final String ownerUserId; // User ID (e.g. U001)
  String name;
  String category;
  String location;
  String image;
  String about;
  bool isFollowed;
  bool isSubscribed;
  List<PostItem> posts;

  BusinessProfile({
    required this.businessProfileId,
    required this.ownerUserId,
    required this.name,
    required this.category,
    required this.location,
    required this.image,
    required this.about,
    this.isFollowed = false,
    this.isSubscribed = false,
    List<PostItem>? posts,
  }) : posts = posts ?? [];
}

class BusinessService extends ChangeNotifier {
  final List<BusinessProfile> _businesses = [
    BusinessProfile(
      businessProfileId: "BP001",
      ownerUserId: "U001",
      name: "ABC Dental Clinic",
      category: "Dental Clinic",
      location: "Tirunelveli",
      isFollowed: true,
      image: "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=300&q=80",
      about: "We provide quality dental care and regular dental checkups.",
      posts: [
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
          image: "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80",
          timeAgo: "1 hour ago",
          targetLocation: "Tirunelveli",
        ),
      ],
    ),
    BusinessProfile(
      businessProfileId: "BP002",
      ownerUserId: "U001",
      name: "Tech Solutions",
      category: "IT Services",
      location: "Madurai",
      isFollowed: true,
      image: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=300&q=80",
      about: "We provide professional software development and IT solutions for businesses.",
      posts: [
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
          targetLocation: "Madurai",
        ),
      ],
    ),
    BusinessProfile(
      businessProfileId: "BP003",
      ownerUserId: "U001",
      name: "Sri Lakshmi Electricals",
      category: "Electrical Services",
      location: "Nagercoil",
      isFollowed: false,
      image: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=300&q=80",
      about: "We provide reliable electrical installation, repair, and maintenance services.",
      posts: [
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
          image: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80",
          timeAgo: "3 hours ago",
          targetLocation: "Nagercoil",
        ),
      ],
    ),
  ];

  String? _activeBusinessProfileId = "BP001";

  List<BusinessProfile> get businesses => List.unmodifiable(_businesses);

  List<BusinessProfile> get followedBusinesses =>
      _businesses.where((b) => b.isFollowed).toList();

  BusinessProfile? get activeBusiness {
    if (_activeBusinessProfileId == null) return null;
    try {
      return _businesses.firstWhere((b) => b.businessProfileId == _activeBusinessProfileId);
    } catch (_) {
      return _businesses.isNotEmpty ? _businesses.first : null;
    }
  }

  /// Get business profiles owned by a specific user (fallback guarantees 3 profiles)
  List<BusinessProfile> getUserBusinesses(String userId) {
    final list = _businesses.where((b) => b.ownerUserId == userId || b.ownerUserId == "U001").toList();
    if (list.isEmpty) {
      return _businesses;
    }
    return list;
  }

  void setActiveBusiness(String businessProfileId) {
    _activeBusinessProfileId = businessProfileId;
    notifyListeners();
  }

  /// Purpose: Follow or unfollow a business profile.
  void toggleFollow(String businessProfileId) {
    final index = _businesses.indexWhere((b) => b.businessProfileId == businessProfileId);
    if (index != -1) {
      _businesses[index].isFollowed = !_businesses[index].isFollowed;
      notifyListeners();
    }
  }

  /// Purpose: Subscribe or unsubscribe to business announcements.
  void toggleSubscribe(String businessProfileId) {
    final index = _businesses.indexWhere((b) => b.businessProfileId == businessProfileId);
    if (index != -1) {
      _businesses[index].isSubscribed = !_businesses[index].isSubscribed;
      notifyListeners();
    }
  }

  /// Purpose: Create a new Business Profile.
  Future<BusinessProfile> createBusinessProfile({
    required String ownerUserId,
    required String name,
    required String category,
    required String location,
    required String about,
  }) async {
    final newId = "BP${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(4, '0')}";
    final newBiz = BusinessProfile(
      businessProfileId: newId,
      ownerUserId: ownerUserId,
      name: name,
      category: category,
      location: location,
      image: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=300&q=80",
      about: about.isNotEmpty ? about : "Newly opened business profile.",
    );

    _businesses.add(newBiz);
    _activeBusinessProfileId = newId;
    notifyListeners();
    return newBiz;
  }

  BusinessProfile? getBusinessById(String id) {
    try {
      return _businesses.firstWhere((b) => b.businessProfileId == id);
    } catch (_) {
      return null;
    }
  }

  void updateBusinessProfile({
    required String businessProfileId,
    required String name,
    required String category,
    required String location,
    required String about,
  }) {
    final biz = getBusinessById(businessProfileId);
    if (biz != null) {
      biz.name = name;
      biz.category = category;
      biz.location = location;
      biz.about = about;
      notifyListeners();
    }
  }

  void addPostToBusiness(String businessProfileId, PostItem post) {
    final biz = getBusinessById(businessProfileId);
    if (biz != null) {
      biz.posts.insert(0, post);
      notifyListeners();
    }
  }
}
