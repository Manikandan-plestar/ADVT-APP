import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_service.dart';
import '../services/business_service.dart';
import '../services/post_service.dart';
import '../widgets/home/business_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchService = Provider.of<SearchService>(context);
    final bizService = Provider.of<BusinessService>(context);
    final postService = Provider.of<PostService>(context);

    final results = searchService.search(
      query: _searchController.text,
      businesses: bizService.businesses,
      posts: postService.allPosts,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search businesses, shops...',
                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore Businesses',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            if (results.businesses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No businesses found matching query',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.businesses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final biz = results.businesses[index];
                  return BusinessCard(
                    business: biz,
                    onTap: () {
                      Navigator.pushNamed(context, '/business-details', arguments: biz.businessProfileId);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
