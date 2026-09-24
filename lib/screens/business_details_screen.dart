import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/target_location_model.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../services/post_service.dart';
import '../services/notification_service.dart';
import '../widgets/business/cycling_business_image.dart';
import '../widgets/business/cycling_post_image.dart';
import '../widgets/business/create_post_modal.dart';

class BusinessDetailsScreen extends StatefulWidget {
  final String businessProfileId;

  const BusinessDetailsScreen({
    super.key,
    required this.businessProfileId,
  });

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isInitialLoaded = false;
  bool _showStickyHeader = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialLoaded) {
      _isInitialLoaded = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Trigger sticky header appearance only when hero image/details scroll away
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final show = _scrollController.offset > 240;
    if (_showStickyHeader != show) {
      setState(() {
        _showStickyHeader = show;
      });
    }
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bizService = Provider.of<BusinessService>(context, listen: false);
    final postService = Provider.of<PostService>(context, listen: false);

    // Fetch user businesses if not present
    if (bizService.getBusinessById(widget.businessProfileId) == null) {
      if (authService.currentUser.userId.isNotEmpty || authService.currentUser.email.isNotEmpty) {
        await bizService.fetchUserBusinesses(
          userId: authService.currentUser.userId,
          authToken: authService.currentUser.authToken,
          userEmail: authService.currentUser.email,
        );
      }
    }

    // Fetch posts for this business
    await postService.fetchPosts(businessId: widget.businessProfileId);
  }

  void _showPostTypeMenu(BuildContext context, BusinessProfile biz) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Create New Listing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),

              // 1. Job Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline_rounded, color: Color(0xFF4F46E5), size: 22),
                ),
                title: const Text('Job Opening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Hire candidates for full-time, part-time, or remote roles', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreatePostModal(context, 'job', biz);
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 2. Offer Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_offer_outlined, color: Color(0xFFD97706), size: 22),
                ),
                title: const Text('Special Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Publish seasonal discounts, flash sales, or combo deals', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreatePostModal(context, 'offer', biz);
                },
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // 3. Coupon Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF059669), size: 22),
                ),
                title: const Text('Coupon Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Distribute promo codes with expiry dates and terms', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openCreatePostModal(context, 'coupon', biz);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreatePostModal(BuildContext context, String postType, BusinessProfile biz) {
    final postService = Provider.of<PostService>(context, listen: false);
    final bizService = Provider.of<BusinessService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final notifService = Provider.of<NotificationService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreatePostModal(
        postType: postType,
        onSubmit: ({
          required String title,
          required String subtitle,
          required String description,
          required String targetLocation,
          String? couponCode,
          List<TargetLocationModel>? targetLocations,
          List<String>? images,
        }) async {
          final newPost = await postService.createPost(
            businessProfileId: biz.businessProfileId,
            bizName: biz.name,
            type: postType,
            title: title,
            subtitle: subtitle,
            description: description,
            couponCode: couponCode,
            targetLocation: targetLocation,
            targetLocationItems: targetLocations,
            images: images,
            authToken: authService.currentUser.authToken,
            userId: authService.currentUser.userId,
            userEmail: authService.currentUser.email,
          );

          bizService.addPostToBusiness(biz.businessProfileId, newPost);

          notifService.addNotification(
            title: postType == 'job'
                ? 'New Job Opening'
                : (postType == 'coupon' ? 'New Coupon Published' : 'Special Offer Alert'),
            message: '${biz.name} published "$title" in $targetLocation.',
            type: postType,
          );
        },
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, PostItem post, String bizId) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final postService = Provider.of<PostService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to delete "${post.displayTitle}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await postService.deletePost(
                post.postId,
                callerBusinessProfileId: bizId,
                authToken: authService.currentUser.authToken,
                userId: authService.currentUser.userId,
                userEmail: authService.currentUser.email,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Post deleted successfully.' : 'Failed to delete post.'),
                    backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bizService = Provider.of<BusinessService>(context);
    final postService = Provider.of<PostService>(context);

    final biz = bizService.getBusinessById(widget.businessProfileId);

    // Requirement 14: Show clean skeleton/loading state while waiting
    if (biz == null) {
      if (bizService.isLoading) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF4F46E5), strokeWidth: 2),
          ),
        );
      }
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Business Profile', style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: Text('Business profile not found', style: TextStyle(color: Color(0xFF6B7280))),
        ),
      );
    }

    // Posts associated with this specific Business Profile ID
    final cleanBizId = biz.businessProfileId.replaceAll(RegExp(r'[^0-9]'), '');
    final relatedPosts = postService.allPosts.where((p) {
      final pBizId = p.businessProfileId.replaceAll(RegExp(r'[^0-9]'), '');
      final pNum = p.numericBusinessId?.toString();
      return p.businessProfileId == biz.businessProfileId ||
          (cleanBizId.isNotEmpty && pBizId == cleanBizId) ||
          (cleanBizId.isNotEmpty && pNum == cleanBizId);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF4F46E5),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // ========================================================
            // 1. TOP APP BAR (Sticky header appears ONLY after scrolling)
            // ========================================================
            SliverAppBar(
              pinned: true,
              elevation: _showStickyHeader ? 1.0 : 0.0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827), size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              // Requirement 1 & 2: Show Business Name & Category in sticky header ONLY after scrolling down
              title: AnimatedOpacity(
                opacity: _showStickyHeader ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _showStickyHeader
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  biz.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF3B82F6)),
                            ],
                          ),
                          Text(
                            biz.displayCategory,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              // Requirement 1 & 2: Show Edit & + icons in sticky header ONLY after scrolling down
              actions: [
                AnimatedOpacity(
                  opacity: _showStickyHeader ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _showStickyHeader
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5), size: 20),
                              tooltip: 'Edit Profile',
                              onPressed: () {
                                Navigator.pushNamed(context, '/edit-biz', arguments: biz.businessProfileId);
                              },
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEEF2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_rounded, color: Color(0xFF4F46E5), size: 20),
                              ),
                              tooltip: 'Create Post',
                              onPressed: () => _showPostTypeMenu(context, biz),
                            ),
                            const SizedBox(width: 8),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),

            // ========================================================
            // 2. HERO BUSINESS IMAGES (Cycles every 3 seconds)
            // ========================================================
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  CyclingBusinessImage(
                    images: biz.images,
                    width: double.infinity,
                    height: 260,
                    interval: const Duration(seconds: 3),
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.zero,
                  ),
                  if (biz.images.length > 1)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${biz.images.length} photos • 3s',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ========================================================
            // 3. BUSINESS DETAILS WITHOUT CARDS + EDIT & POST ACTIONS
            // ========================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business Name & Category
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            biz.displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, size: 20, color: Color(0xFF3B82F6)),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Category / Profession Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        biz.displayCategory,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    if (biz.phone.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 8),
                          Text(
                            biz.phone,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Address / Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            biz.registeredAddress.isNotEmpty ? biz.registeredAddress : biz.displayLocation,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.35),
                          ),
                        ),
                      ],
                    ),

                    // About section
                    if (biz.about.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        biz.about,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.45),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // --------------------------------------------------------
                    // Requirement: Edit and Post buttons with matching border lines
                    // --------------------------------------------------------
                    Row(
                      children: [
                        // Edit Action (Border color matches text color)
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/edit-biz', arguments: biz.businessProfileId);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF374151), width: 1.5),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF374151)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Post Action (Border color matches text color)
                        Expanded(
                          child: InkWell(
                            onTap: () => _showPostTypeMenu(context, biz),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4F46E5), width: 1.5),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF4F46E5)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Post',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(thickness: 1, color: Color(0xFFF1F5F9)),
                  ],
                ),
              ),
            ),

            // ========================================================
            // 4. POSTS SECTION HEADER
            // ========================================================
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyPostsHeaderDelegate(
                postCount: relatedPosts.length,
              ),
            ),

            // ========================================================
            // 5. EXISTING BUSINESS POSTS LIST
            // ========================================================
            if (relatedPosts.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.post_add_rounded, color: Color(0xFF4F46E5), size: 28),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No listings published yet',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap "+ Post" above to create Jobs, Offers, or Coupons.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = relatedPosts[index];
                      final isJob = post.type == 'job';
                      final isCoupon = post.type == 'coupon';

                      Color badgeBg = isJob
                          ? const Color(0xFFEEF2FF)
                          : (isCoupon ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB));
                      Color badgeFg = isJob
                          ? const Color(0xFF4F46E5)
                          : (isCoupon ? const Color(0xFF059669) : const Color(0xFFD97706));
                      String badgeText = isJob ? 'JOB' : (isCoupon ? 'COUPON' : 'OFFER');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post Images if available
                            if (post.images.isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: CyclingPostImage(
                                  images: post.images,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Badge, Time & Delete Icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: badgeFg,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            post.formattedPostTime,
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            tooltip: 'Delete Post',
                                            onPressed: () => _confirmDeletePost(context, post, biz.businessProfileId),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Post Title
                                  Text(
                                    post.displayTitle,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),

                                  if (post.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      post.subtitle,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                    ),
                                  ],

                                  if (post.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      post.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.3),
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  // Location & Action Details
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF9CA3AF)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          post.displayLocation.isNotEmpty ? post.displayLocation : (post.targetLocation ?? ''),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                                        ),
                                      ),
                                      if (post.couponCode != null && post.couponCode!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            post.couponCode!,
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: relatedPosts.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StickyPostsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int postCount;

  const _StickyPostsHeaderDelegate({
    required this.postCount,
  });

  @override
  double get minExtent => 38.0;

  @override
  double get maxExtent => 38.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'POSTS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.6,
            ),
          ),
          if (postCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$postCount ${postCount == 1 ? 'post' : 'posts'}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyPostsHeaderDelegate oldDelegate) {
    return oldDelegate.postCount != postCount;
  }
}
