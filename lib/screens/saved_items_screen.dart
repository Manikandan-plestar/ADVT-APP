import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/post_service.dart';
import '../widgets/common/empty_state.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = Provider.of<PostService>(context);
    final savedList = postService.savedPosts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (savedList.isEmpty)
              const EmptyStateWidget(
                icon: Icons.bookmark_border_rounded,
                title: 'No saved items yet',
                subtitle: 'Click save on any post to bookmark it',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: savedList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = savedList[index];
                  final isJob = item.type == 'job';
                  final isCoupon = item.type == 'coupon';
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (isJob) {
                                Navigator.pushNamed(context, '/job-details', arguments: item.postId);
                              } else if (isCoupon) {
                                Navigator.pushNamed(context, '/coupon-details', arguments: item.postId);
                              } else {
                                Navigator.pushNamed(context, '/offer-details', arguments: item.postId);
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isJob
                                        ? const Color(0xFFEEF2FF)
                                        : (isCoupon ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.type.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isJob
                                          ? const Color(0xFF4F46E5)
                                          : (isCoupon ? const Color(0xFF047857) : const Color(0xFFD97706)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => postService.toggleSavePost(item.postId),
                          child: const Text(
                            'Remove',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
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
