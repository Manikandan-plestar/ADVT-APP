import 'package:flutter/foundation.dart';
import 'business_service.dart';
import 'post_service.dart';

class SearchResult {
  final List<BusinessProfile> businesses;
  final List<PostItem> posts;

  SearchResult({required this.businesses, required this.posts});
}

class SearchService extends ChangeNotifier {
  String _query = '';
  String get query => _query;

  /// Purpose: Search businesses, jobs, offers, categories, and professions.
  /// Current behavior: Performs local fuzzy search over business & post arrays.
  /// Future behavior: Send GET /search?q=query API request to Node.js backend.
  SearchResult search({
    required String query,
    required List<BusinessProfile> businesses,
    required List<PostItem> posts,
  }) {
    _query = query.trim().toLowerCase();

    if (_query.isEmpty) {
      return SearchResult(businesses: businesses, posts: posts);
    }

    final matchedBiz = businesses.where((b) {
      return b.name.toLowerCase().contains(_query) ||
          b.category.toLowerCase().contains(_query) ||
          b.location.toLowerCase().contains(_query) ||
          b.about.toLowerCase().contains(_query);
    }).toList();

    final matchedPosts = posts.where((p) {
      return p.title.toLowerCase().contains(_query) ||
          p.subtitle.toLowerCase().contains(_query) ||
          p.description.toLowerCase().contains(_query) ||
          p.bizName.toLowerCase().contains(_query);
    }).toList();

    return SearchResult(businesses: matchedBiz, posts: matchedPosts);
  }
}
