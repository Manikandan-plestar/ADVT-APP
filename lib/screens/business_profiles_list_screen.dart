import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/business_service.dart';
import '../widgets/home/business_card.dart';

class BusinessProfilesListScreen extends StatelessWidget {
  const BusinessProfilesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bizService = Provider.of<BusinessService>(context);

    final userBusinesses = bizService.getUserBusinesses(authService.currentUser.userId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Business Profiles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
            child: Column(
              children: [
                if (userBusinesses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No business profiles registered yet.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userBusinesses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final biz = userBusinesses[index];
                      return BusinessCard(
                        business: biz,
                        onTap: () {
                          bizService.setActiveBusiness(biz.businessProfileId);
                          Navigator.pushNamed(context, '/biz-manage');
                        },
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Manage',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Add New Business Profile Button
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/create-biz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Add New Business Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
