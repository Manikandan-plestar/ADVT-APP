import 'package:flutter/material.dart';
import 'curved_nav_bar_clipper.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterPlusTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCenterPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF4F46E5); // Indigo
    const inactiveColor = Color(0xFF6B7280); // Gray 500

    return SizedBox(
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Shadow & Curved Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: CurvedNavBarClipper(),
                child: Container(
                  height: 72,
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Item 0: Home
                      _buildNavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isActive: currentIndex == 0,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTap(0),
                      ),
                      // Item 1: Search
                      _buildNavItem(
                        icon: Icons.search_rounded,
                        label: 'Search',
                        isActive: currentIndex == 1,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTap(1),
                      ),
                      // Spacer for center elevated (+) button
                      const SizedBox(width: 56),
                      // Item 2: Coupons
                      _buildNavItem(
                        icon: Icons.confirmation_number_rounded,
                        label: 'Coupons',
                        isActive: currentIndex == 2,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTap(2),
                      ),
                      // Item 3: Profile
                      _buildNavItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        isActive: currentIndex == 3,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => onTap(3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Elevated Center Plus (+) Action Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onCenterPlusTap,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
