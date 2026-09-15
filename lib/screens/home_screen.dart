import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/post_service.dart';
import '../services/business_service.dart';
import '../services/notification_service.dart';
import '../widgets/common/bottom_navigation.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/home/post_card.dart';
import '../widgets/home/filter_dropdown.dart';
import '../widgets/business/select_profile_modal.dart';
import 'search_screen.dart';
import 'followed_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentBottomNavIndex = 0;
  bool _isFilterDropdownOpen = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentBottomNavIndex,
              children: [
                _buildHomeFeedTab(),
                const SearchScreen(),
                const FollowedScreen(),
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
    final notifService = Provider.of<NotificationService>(context);

    final followedIds = bizService.followedBusinesses.map((b) => b.businessProfileId).toList();
    final feedPosts = postService.getFilteredPosts(followedIds);

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
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
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
                                    locationService.currentLocation.formattedAddress,
                                    style: const TextStyle(
                                      fontSize: 11,
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
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/notifications');
                            },
                            icon: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF4B5563), size: 20),
                            ),
                          ),
                          if (notifService.unreadCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search Bar & Filter Button Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentBottomNavIndex = 1;
                            });
                          },
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                                SizedBox(width: 8),
                                Text(
                                  'Search jobs, offers, businesses...',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
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
                        icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Feed Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 96),
                child: Column(
                  children: [
                    // Feed Heading Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          filterTitleMap[postService.activeFilter] ?? 'Recommended Feed',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            postService.activeFilter.toUpperCase(),
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
                    if (feedPosts.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.inbox_rounded,
                        title: 'No items match this filter',
                        subtitle: postService.activeFilter == 'followed'
                            ? "You haven't followed any business with posts yet."
                            : 'Try choosing another category.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: feedPosts.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = feedPosts[index];
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
