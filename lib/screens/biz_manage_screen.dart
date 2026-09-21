import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/target_location_model.dart';
import '../services/business_service.dart';
import '../services/post_service.dart';
import '../services/notification_service.dart';
import '../widgets/business/create_post_modal.dart';
import '../widgets/business/cycling_post_image.dart';

class BizManageScreen extends StatelessWidget {
  const BizManageScreen({super.key});

  void _openCreatePostModal(BuildContext context, String postType, String bizId, String bizName) {
    final postService = Provider.of<PostService>(context, listen: false);
    final bizService = Provider.of<BusinessService>(context, listen: false);
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
            businessProfileId: bizId,
            bizName: bizName,
            type: postType,
            title: title,
            subtitle: subtitle,
            description: description,
            couponCode: couponCode,
            targetLocation: targetLocation,
            targetLocationItems: targetLocations,
            images: images,
          );

          bizService.addPostToBusiness(bizId, newPost);

          notifService.addNotification(
            title: postType == 'job'
                ? 'New Job Opening'
                : (postType == 'coupon' ? 'New Coupon Published' : 'Special Offer Alert'),
            message: '$bizName published "$title" in $targetLocation.',
            type: postType,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bizService = Provider.of<BusinessService>(context);
    final postService = Provider.of<PostService>(context);
    final activeBiz = bizService.activeBusiness;

    if (activeBiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Management')),
        body: const Center(child: Text('No active business selected')),
      );
    }

    // Refresh posts dynamically from postService to ensure deleted posts disappear immediately
    final bizPosts = postService.allPosts
        .where((p) => p.businessProfileId == activeBiz.businessProfileId)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeBiz.displayName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            Text(
              '${activeBiz.displayCategory} • ${activeBiz.displayLocation}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5)),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/edit-biz', arguments: activeBiz.businessProfileId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Three Direct Post Buttons (Job, Offer, Coupon)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreatePostModal(context, 'job', activeBiz.businessProfileId, activeBiz.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEF2FF),
                      foregroundColor: const Color(0xFF4338CA),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.work_outline_rounded, size: 15),
                    label: const Text('Job', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreatePostModal(context, 'offer', activeBiz.businessProfileId, activeBiz.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFBEB),
                      foregroundColor: const Color(0xFFB45309),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.local_offer_outlined, size: 15),
                    label: const Text('Offer', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreatePostModal(context, 'coupon', activeBiz.businessProfileId, activeBiz.name),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFECFDF5),
                      foregroundColor: const Color(0xFF047857),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.confirmation_number_outlined, size: 15),
                    label: const Text('Coupon', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'ACTIVE LISTINGS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            if (bizPosts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                ),
                child: const Column(
                  children: [
                    Text(
                      'No active postings',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Use the buttons above to post job vacancies, discounts, or coupons.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bizPosts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final post = bizPosts[index];
                  final isJob = post.type == 'job';
                  final isCoupon = post.type == 'coupon';

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      if (isJob) {
                        Navigator.pushNamed(context, '/job-details', arguments: post.postId);
                      } else if (isCoupon) {
                        Navigator.pushNamed(context, '/coupon-details', arguments: post.postId);
                      } else {
                        Navigator.pushNamed(context, '/offer-details', arguments: post.postId);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x04000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // If post has images, display cycling post images with 5s interval
                          if (post.images.isNotEmpty)
                            CyclingPostImage(
                              images: post.images,
                              height: 140,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              interval: const Duration(seconds: 5),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: isJob
                                            ? const Color(0xFFEEF2FF)
                                            : (isCoupon ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB)),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isJob ? 'JOB' : (isCoupon ? 'COUPON' : 'OFFER'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isJob
                                              ? const Color(0xFF4F46E5)
                                              : (isCoupon ? const Color(0xFF047857) : const Color(0xFFD97706)),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  post.title,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  post.subtitle,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  post.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563), height: 1.3),
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                                const SizedBox(height: 8),

                                // Bottom Footer: Target Location (left) + Post Time (bottom-right corner)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (post.targetLocation != null && post.targetLocation!.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF9CA3AF)),
                                          const SizedBox(width: 3),
                                          Text(
                                            post.targetLocation!,
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    Text(
                                      post.formattedPostTime,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
