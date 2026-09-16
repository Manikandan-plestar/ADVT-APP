import 'package:flutter/foundation.dart';
import 'post_service.dart';

class BusinessProfile {
  final String businessProfileId; // Unique ID (e.g. BP001), NOT phone number!
  final String ownerUserId; // User ID (e.g. U001)
  String name;
  String category;
  String phone; // Business contact number with country code
  final String location; // Registered City / Area (Fixed)
  final String registeredAddress; // Full Reverse Geocoded Address (Fixed)
  final double latitude; // Fixed GPS Latitude
  final double longitude; // Fixed GPS Longitude
  String image;
  List<String> images; // 1 to 4 business profile images
  String about;
  bool isFollowed;
  bool isSubscribed;
  List<PostItem> posts;

  BusinessProfile({
    required this.businessProfileId,
    required this.ownerUserId,
    required this.name,
    required this.category,
    this.phone = '+91 98402 12345',
    required this.location,
    this.registeredAddress = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.image,
    List<String>? images,
    required this.about,
    this.isFollowed = false,
    this.isSubscribed = false,
    List<PostItem>? posts,
  })  : images = (images != null && images.isNotEmpty) ? images : [image],
        posts = posts ?? [];
}

class BusinessService extends ChangeNotifier {
  final List<BusinessProfile> _businesses = [
    BusinessProfile(
      businessProfileId: "BP001",
      ownerUserId: "U001",
      name: "ABC Dental Clinic",
      category: "Dental Clinic",
      phone: "+91 98402 11001",
      location: "Tirunelveli",
      registeredAddress: "12, High Ground Road, Palayamkottai, Tirunelveli - 627002",
      latitude: 8.7139,
      longitude: 77.7567,
      isFollowed: true,
      image: "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80",
      images: [
        "https://images.unsplash.com/photo-1629909613654-28e377c37b09?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=600&q=80",
      ],
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
      phone: "+91 98402 22002",
      location: "Madurai",
      registeredAddress: "45, Bypass Road, Madurai - 625016",
      latitude: 9.9252,
      longitude: 78.1198,
      isFollowed: true,
      image: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=600&q=80",
      images: [
        "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=600&q=80",
        "https://images.unsplash.com/photo-1531482615713-2afd69097998?auto=format&fit=crop&w=600&q=80",
      ],
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
      phone: "+91 98402 33003",
      location: "Nagercoil",
      registeredAddress: "88, Main Bazaar Street, Nagercoil - 629001",
      latitude: 8.1833,
      longitude: 77.4119,
      isFollowed: false,
      image: "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80",
      images: [
        "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80",
      ],
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

  /// Purpose: Create a new Business Profile with permanently fixed GPS location.
  Future<BusinessProfile> createBusinessProfile({
    required String ownerUserId,
    required String name,
    required String category,
    required String phone,
    required String location,
    required String registeredAddress,
    required double latitude,
    required double longitude,
    required List<String> images,
    required String about,
  }) async {
    final newId = "BP${(DateTime.now().millisecondsSinceEpoch % 100000).toString().padLeft(4, '0')}";
    final primaryImage = images.isNotEmpty
        ? images.first
        : "https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=600&q=80";

    final newBiz = BusinessProfile(
      businessProfileId: newId,
      ownerUserId: ownerUserId,
      name: name,
      category: category,
      phone: phone,
      location: location,
      registeredAddress: registeredAddress.isNotEmpty ? registeredAddress : location,
      latitude: latitude,
      longitude: longitude,
      image: primaryImage,
      images: images.isNotEmpty ? images : [primaryImage],
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

  /// Purpose: Update editable details of a business profile.
  /// Location, coordinates, and registered address are permanently locked for fraud prevention.
  void updateBusinessProfile({
    required String businessProfileId,
    required String name,
    required String category,
    required String phone,
    required List<String> images,
    required String about,
  }) {
    final biz = getBusinessById(businessProfileId);
    if (biz != null) {
      biz.name = name;
      biz.category = category;
      biz.phone = phone;
      if (images.isNotEmpty) {
        biz.images = List.from(images);
        biz.image = images.first;
      }
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
