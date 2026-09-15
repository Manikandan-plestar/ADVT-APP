import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/business_service.dart';
import '../services/post_service.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Cover Gradient Banner with Overlay Avatar & Follow Button
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF9333EA)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -32,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 4),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        biz.image,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 72,
                            height: 72,
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF4F46E5)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 72,
                          height: 72,
                          color: const Color(0xFFEEF2FF),
                          child: const Icon(Icons.store_rounded, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () => bizService.toggleFollow(biz.businessProfileId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: biz.isFollowed ? const Color(0xFFF3F4F6) : const Color(0xFF4F46E5),
                      foregroundColor: biz.isFollowed ? const Color(0xFF374151) : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      biz.isFollowed ? '✓ Following' : '+ Follow',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 44),

            // Business Identity Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        biz.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF3B82F6)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${biz.category} • ${biz.location}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    biz.about,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 16),

            // Recent Updates Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECENT UPDATES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 12),
                  if (relatedPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No current public announcements.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: relatedPosts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final post = relatedPosts[index];
                        final isJob = post.type == 'job';
                        return GestureDetector(
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
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isJob ? const Color(0xFFEEF2FF) : const Color(0xFFFFFBEB),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        post.type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isJob ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        post.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  post.subtitle,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
          ],
        ),
      ),
    );
  }
}
