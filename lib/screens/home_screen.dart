import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/post_service.dart';
import '../services/business_service.dart';
import '../services/notification_service.dart';
import '../services/search_service.dart';
import '../widgets/common/bottom_navigation.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/home/post_card.dart';
import '../widgets/home/filter_dropdown.dart';
import '../widgets/business/select_profile_modal.dart';
import 'search_screen.dart';
import 'coupons_screen.dart';
import 'profile_screen.dart';
import '../widgets/common/notification_bell_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  bool _isFilterDropdownOpen = false;
  final _postSearchController = TextEditingController();
  bool _isInitialLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoaded) {
      _isInitialLoaded = true;
      final postService = Provider.of<PostService>(context, listen: false);
      postService.fetchPosts();
    }
  }

  @override
  void dispose() {
    _postSearchController.dispose();
    super.dispose();
  }

  void _handleCenterPlusClick() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bizService = Provider.of<BusinessService>(context, listen: false);

    final userBusinesses = bizService.getUserBusinesses(authService.currentUser.userId);

    if (userBusinesses.isEmpty) {
      Navigator.pushNamed(context, '/create-biz');
    } else if (userBusinesses.length == 1) {
      bizService.setActiveBusiness(userBusinesses.first.businessProfileId);
      Navigator.pushNamed(context, '/biz-manage');
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SelectProfileModal(
          userBusinesses: userBusinesses,
          onSelectProfile: (biz) {
            bizService.setActiveBusiness(biz.businessProfileId);
            Navigator.pushNamed(context, '/biz-manage');
          },
        ),
      );
    }
  }

  String _formatGreetingAddress(LocationDetails loc, String userAddress) {
    if (loc.area.isNotEmpty && loc.district.isNotEmpty && loc.area != loc.district) {
      return '${loc.area}, ${loc.district}';
    }
    if (loc.city.isNotEmpty && loc.district.isNotEmpty && loc.city != loc.district) {
      return '${loc.city}, ${loc.district}';
    }
    if (loc.area.isNotEmpty) return loc.area;
    if (loc.city.isNotEmpty) return loc.city;
    if (loc.district.isNotEmpty) return loc.district;

    if (userAddress.isNotEmpty) {
      final parts = userAddress.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        final cleanDist = parts[parts.length - 1].split('-')[0].trim();
        return '${parts[parts.length - 2]}, $cleanDist';
      } else if (parts.isNotEmpty) {
        return parts.first;
      }
    }
    return 'Palayamkottai, Tirunelveli';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Current Selected Tab Screen
            IndexedStack(
              index: _currentBottomNavIndex,
              children: [
                _buildHomeFeedTab(),
                const CouponsScreen(),
                const SearchScreen(),
                const ProfileScreen(),
              ],
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: _currentBottomNavIndex,
                onTap: (index) {
                  setState(() {
                    _currentBottomNavIndex = index;
                    _isFilterDropdownOpen = false;
                  });
                },
                onCenterPlusTap: _handleCenterPlusClick,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeFeedTab() {
    final authService = Provider.of<AuthService>(context);
    final locationService = Provider.of<LocationService>(context);
    final postService = Provider.of<PostService>(context);
    final bizService = Provider.of<BusinessService>(context);
    final searchService = Provider.of<SearchService>(context);

    final followedIds = bizService.followedBusinesses.map((b) => b.businessProfileId).toList();
    final feedPosts = postService.getFilteredPosts(followedIds);
    final isSearchingPosts = _postSearchController.text.trim().isNotEmpty;
    final displayedPosts = isSearchingPosts
        ? searchService.searchPosts(query: _postSearchController.text, posts: feedPosts)
        : feedPosts;

    final filterTitleMap = {
      'all': 'Recommended Feed',
      'jobs': 'Available Jobs',
      'offers': 'Active Offers & Deals',
      'followed': 'Updates From Followed Stores',
    };

    return Stack(
      children: [
        Column(
          children: [
            // Top Header Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4F46E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pin_drop_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning, ${authService.currentUser.name.split(' ')[0]}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatGreetingAddress(
                                      locationService.currentLocation,
                                      authService.currentUser.address,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Notification Bell Trigger
                      const NotificationBellButton(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search Bar & Filter Button Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _postSearchController,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF111827)),
                                  decoration: const InputDecoration(
                                    hintText: 'Search jobs, offers, stores...',
                                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              if (_postSearchController.text.isNotEmpty)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    _postSearchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isFilterDropdownOpen = !_isFilterDropdownOpen;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.filter_alt_rounded, color: Colors.white, size: 19),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Feed Content Area with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await postService.fetchPosts();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Feed Title + Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            filterTitleMap[postService.activeFilter] ?? 'Feed',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isSearchingPosts ? 'SEARCH' : postService.activeFilter.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Feed Items or Empty State
                      if (displayedPosts.isEmpty)
                        EmptyStateWidget(
                          icon: isSearchingPosts ? Icons.search_off_rounded : Icons.inbox_rounded,
                          title: isSearchingPosts
                              ? 'No posts found for "${_postSearchController.text.trim()}"'
                              : 'No items match this filter',
                          subtitle: isSearchingPosts
                              ? 'Try searching by job role, offer deal, city, or company name.'
                              : (postService.activeFilter == 'followed'
                                  ? "You haven't followed any business with posts yet."
                                  : 'Try choosing another category.'),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedPosts.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = displayedPosts[index];
                            return PostCard(
                              item: item,
                              onView: () {
                                if (item.type == 'job') {
                                  Navigator.pushNamed(context, '/job-details', arguments: item.postId);
                                } else {
                                  Navigator.pushNamed(context, '/offer-details', arguments: item.postId);
                                }
                              },
                              onToggleSave: () {
                                postService.toggleSavePost(item.postId);
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Floating Filter Dropdown Popup
        if (_isFilterDropdownOpen)
          Positioned(
            top: 110,
            right: 20,
            child: FilterDropdown(
              activeFilter: postService.activeFilter,
              onSelectFilter: (filterKey) {
                postService.setActiveFilter(filterKey);
                setState(() {
                  _isFilterDropdownOpen = false;
                });
              },
            ),
          ),
      ],
    );
  }
}
