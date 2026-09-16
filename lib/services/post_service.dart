import 'package:flutter/foundation.dart';
import '../models/target_location_model.dart';

class PostItem {
  final String postId;
  final String businessProfileId;
  final String bizName;
  final String type; // 'job' or 'offer'
  final String title;
  final String subtitle;
  final String description;
  final String? exp;
  final String? jobType;
  final List<String> images; // Ordered list of post images
  final String? validity;
  final String? discount;
  final String timeAgo;
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
    required this.timeAgo,
    this.targetLocation,
    this.targetLocationItems,
    this.isSaved = false,
  }) : images = (images != null && images.isNotEmpty)
            ? images
            : (image != null && image.isNotEmpty ? [image] : []);

  /// Backward compatibility getter for single-image references
  String? get image => images.isNotEmpty ? images.first : null;
}

class PostService extends ChangeNotifier {
  final List<PostItem> _feedPosts = [
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
      targetLocation: "Nagercoil",
      isSaved: false,
    ),
  ];

  String _activeFilter = 'all'; // 'all', 'jobs', 'offers', 'followed'

  String get activeFilter => _activeFilter;
  List<PostItem> get allPosts => List.unmodifiable(_feedPosts);
  List<PostItem> get savedPosts => _feedPosts.where((p) => p.isSaved).toList();

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  /// Get filtered feed posts based on active filter and followed business profile IDs
  List<PostItem> getFilteredPosts(List<String> followedProfileIds) {
    return _feedPosts.where((post) {
      if (_activeFilter == 'all') return true;
      if (_activeFilter == 'jobs') return post.type == 'job';
      if (_activeFilter == 'offers') return post.type == 'offer';
      if (_activeFilter == 'followed') {
        return followedProfileIds.contains(post.businessProfileId);
      }
      return true;
    }).toList();
  }

  /// Purpose: Save or unsave (bookmark) a post.
  void toggleSavePost(String postId) {
    final index = _feedPosts.indexWhere((p) => p.postId == postId);
    if (index != -1) {
      _feedPosts[index].isSaved = !_feedPosts[index].isSaved;
      notifyListeners();
    }
  }

  /// Purpose: Create and publish a new post from a business profile.
  Future<PostItem> createPost({
    required String businessProfileId,
    required String bizName,
    required String type,
    required String title,
    required String subtitle,
    required String description,
    String? image,
    List<String>? images,
    String? targetLocation,
    List<TargetLocationModel>? targetLocationItems,
  }) async {
    final selectedImages = (images != null && images.isNotEmpty)
        ? images
        : (image != null && image.isNotEmpty ? [image] : <String>[]);

    final newPost = PostItem(
      postId: DateTime.now().millisecondsSinceEpoch.toString(),
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
      validity: type == 'offer' ? "Active now" : null,
      discount: type == 'offer' ? "SPECIAL DEAL" : null,
      targetLocation: targetLocation,
      targetLocationItems: targetLocationItems,
      isSaved: false,
    );

    _feedPosts.insert(0, newPost);
    notifyListeners();
    return newPost;
  }

  PostItem? getPostById(String postId) {
    try {
      return _feedPosts.firstWhere((p) => p.postId == postId);
    } catch (_) {
      return null;
    }
  }
}
