import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/business_service.dart';
import '../services/post_service.dart';
import '../widgets/business/cycling_business_image.dart';

class BusinessDetailsScreen extends StatelessWidget {
  final String businessProfileId;

  const BusinessDetailsScreen({super.key, required this.businessProfileId});

  @override
  Widget build(BuildContext context) {
    final bizService = Provider.of<BusinessService>(context);
    final postService = Provider.of<PostService>(context);

    final biz = bizService.getBusinessById(businessProfileId);
    if (biz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: const Center(child: Text('Business profile not found')),
      );
    }

    final relatedPosts = postService.allPosts.where((p) => p.businessProfileId == biz.businessProfileId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // 1. Collapsible Hero App Bar with Business Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            elevation: 0.5,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final top = constraints.biggest.height;
                final isCollapsed = top <= kToolbarHeight + MediaQuery.of(context).padding.top + 20;

                return FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
                  title: isCollapsed
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                biz.name,
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
                        )
                      : null,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CyclingBusinessImage(
                        images: biz.images,
                        width: double.infinity,
                        height: 250,
                        borderRadius: BorderRadius.zero,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black54, Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      if (biz.images.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
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
                );
              },
            ),
          ),

          // 2. Business Profile Details (Scrolls away with header)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),

                // Shop Name & Follow Action Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                biz.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF3B82F6)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => bizService.toggleFollow(biz.businessProfileId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: biz.isFollowed ? const Color(0xFFF3F4F6) : const Color(0xFF4F46E5),
                          foregroundColor: biz.isFollowed ? const Color(0xFF374151) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          biz.isFollowed ? '✓ Following' : '+ Follow',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Shop Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Pill
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                biz.category,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Address / Location
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEF4444)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                biz.registeredAddress.isNotEmpty ? biz.registeredAddress : biz.location,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Phone
                        Row(
                          children: [
                            const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 6),
                            Text(
                              biz.phone.isNotEmpty ? biz.phone : '+91 98402 12345',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // About
                        Text(
                          biz.about,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),

          // 3. Sticky Recent Updates Header
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyRecentUpdatesHeaderDelegate(
              postCount: relatedPosts.length,
            ),
          ),

          // 4. Scrollable Posts List (directly below Recent Updates without blank gaps)
          if (relatedPosts.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Center(
                  child: Text(
                    'No current public announcements.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          if (isJob) {
                            Navigator.pushNamed(context, '/job-details', arguments: post.postId);
                          } else {
                            Navigator.pushNamed(context, '/offer-details', arguments: post.postId);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 1)),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: isJob ? const Color(0xFFEEF2FF) : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isJob ? 'JOB' : 'OFFER',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isJob ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      post.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      post.subtitle,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                    ),
                                  ),
                                  Text(
                                    post.formattedPostTime,
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: relatedPosts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StickyRecentUpdatesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int postCount;

  const _StickyRecentUpdatesHeaderDelegate({
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
            'RECENT UPDATES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
              letterSpacing: 0.5,
            ),
          ),
          if (postCount > 0)
            Text(
              '$postCount ${postCount == 1 ? 'post' : 'posts'}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9CA3AF),
              ),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyRecentUpdatesHeaderDelegate oldDelegate) {
    return oldDelegate.postCount != postCount;
  }
}

