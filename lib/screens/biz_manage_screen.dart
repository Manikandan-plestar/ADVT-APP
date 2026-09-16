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
            targetLocation: targetLocation,
            targetLocationItems: targetLocations,
            images: images,
          );

          bizService.addPostToBusiness(bizId, newPost);

          // Trigger mock Notification alert (Requirement #6, #7, #11)
          notifService.addNotification(
            title: postType == 'job' ? 'New Job Opening' : 'Special Offer Alert',
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
    final activeBiz = bizService.activeBusiness;

    if (activeBiz == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Management')),
        body: const Center(child: Text('No active business selected')),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeBiz.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            Text(
              '${activeBiz.category} • ${activeBiz.location}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF4F46E5)),
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
            // Quick Action Card: Publish New Post
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Publish New Post',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openCreatePostModal(context, 'job', activeBiz.businessProfileId, activeBiz.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEEF2FF),
                            foregroundColor: const Color(0xFF4338CA),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.work_outline_rounded, size: 16),
                          label: const Text('Post a Job', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openCreatePostModal(context, 'offer', activeBiz.businessProfileId, activeBiz.name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEB),
                            foregroundColor: const Color(0xFFB45309),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.local_offer_outlined, size: 16),
                          label: const Text('Post an Offer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'ACTIVE LISTINGS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5),
            ),
            const SizedBox(height: 12),

            if (activeBiz.posts.isEmpty)
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
                      'Use the buttons above to post job vacancies or discounts.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeBiz.posts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final post = activeBiz.posts[index];
                  final isJob = post.type == 'job';
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // If post has images, display cycling post images with 5s interval
                        if (post.images.isNotEmpty)
                          CyclingPostImage(
                            images: post.images,
                            height: 120,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            interval: const Duration(seconds: 5),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isJob ? const Color(0xFFEEF2FF) : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isJob ? 'JOB LISTING' : 'OFFER / DEAL',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isJob ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                  const Text('Live', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                post.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                post.subtitle,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                post.description,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                              ),
                            ],
                          ),
                        ),
                      ],
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
