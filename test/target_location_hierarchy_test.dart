import 'package:flutter_test/flutter_test.dart';
import 'package:advt_app/models/target_location_model.dart';
import 'package:advt_app/services/target_location_service.dart';
import 'package:advt_app/services/post_service.dart';

void main() {
  group('Target Location Hierarchical Filtering Tests', () {
    final service = TargetLocationService();

    final india = TargetLocationService.defaultLocations.firstWhere((e) => e.placeId == 'country_in');
    final tamilNadu = TargetLocationService.defaultLocations.firstWhere((e) => e.placeId == 'state_tn');
    final tirunelveli = TargetLocationService.defaultLocations.firstWhere((e) => e.placeId == 'city_tirunelveli');
    final palayamkottai = TargetLocationService.defaultLocations.firstWhere((e) => e.placeId == 'loc_palayamkottai');
    final samathanapuram = TargetLocationService.defaultLocations.firstWhere((e) => e.placeId == 'loc_samathanapuram');
    final ktcNagar = TargetLocationService.defaultLocations.firstWhere((e) => e.placeId == 'loc_ktc_nagar');
    final madurai = TargetLocationService.defaultLocations.firstWhere((e) => e.placeId == 'city_madurai');

    test('Scenario A: Palayamkottai first, then Tirunelveli -> keeps Tirunelveli', () {
      List<TargetLocationModel> current = [];

      // 1. User selects Palayamkottai
      final res1 = service.addAndFilterLocation(currentLocations: current, newLocation: palayamkottai);
      current = res1.updatedLocations;
      expect(current.map((e) => e.name).toList(), ['Palayamkottai']);

      // 2. User selects Tirunelveli (Parent of Palayamkottai)
      final res2 = service.addAndFilterLocation(currentLocations: current, newLocation: tirunelveli);
      current = res2.updatedLocations;

      expect(current.map((e) => e.name).toList(), ['Tirunelveli']);
      expect(res2.removedChildLocations.map((e) => e.name).toList(), ['Palayamkottai']);
    });

    test('Scenario B: Tirunelveli first, then Palayamkottai -> keeps Tirunelveli, rejects child', () {
      List<TargetLocationModel> current = [];

      // 1. User selects Tirunelveli
      final res1 = service.addAndFilterLocation(currentLocations: current, newLocation: tirunelveli);
      current = res1.updatedLocations;
      expect(current.map((e) => e.name).toList(), ['Tirunelveli']);

      // 2. User tries to select Palayamkottai
      final res2 = service.addAndFilterLocation(currentLocations: current, newLocation: palayamkottai);
      current = res2.updatedLocations;

      expect(current.map((e) => e.name).toList(), ['Tirunelveli']);
      expect(res2.wasAlreadyCovered, isTrue);
      expect(res2.coveringParent?.name, 'Tirunelveli');
    });

    test('Scenario C: Palayamkottai and Madurai -> both remain (unrelated)', () {
      List<TargetLocationModel> current = [];

      // 1. User selects Palayamkottai
      final res1 = service.addAndFilterLocation(currentLocations: current, newLocation: palayamkottai);
      current = res1.updatedLocations;

      // 2. User selects Madurai
      final res2 = service.addAndFilterLocation(currentLocations: current, newLocation: madurai);
      current = res2.updatedLocations;

      expect(current.map((e) => e.name).toSet(), {'Palayamkottai', 'Madurai'});
      expect(res2.wasAlreadyCovered, isFalse);
      expect(res2.removedChildLocations, isEmpty);
    });

    test('Scenario D: India, Tamil Nadu, Tirunelveli -> keeps only India (broadest parent)', () {
      final list = [tirunelveli, tamilNadu, india];
      final filtered = service.removeCoveredLocations(list);

      expect(filtered.map((e) => e.name).toList(), ['India']);
    });

    test('Child locations selected first: Palayamkottai, Samathanapuram, KTC Nagar then Tirunelveli', () {
      List<TargetLocationModel> current = [];

      // Select 3 localities
      current = service.addAndFilterLocation(currentLocations: current, newLocation: palayamkottai).updatedLocations;
      current = service.addAndFilterLocation(currentLocations: current, newLocation: samathanapuram).updatedLocations;
      current = service.addAndFilterLocation(currentLocations: current, newLocation: ktcNagar).updatedLocations;
      expect(current.length, 3);

      // Now select parent Tirunelveli
      final res = service.addAndFilterLocation(currentLocations: current, newLocation: tirunelveli);
      current = res.updatedLocations;

      expect(current.map((e) => e.name).toList(), ['Tirunelveli']);
      expect(res.removedChildLocations.length, 3);
      expect(res.removedChildLocations.map((e) => e.name).toSet(), {
        'Palayamkottai',
        'Samathanapuram',
        'KTC Nagar',
      });
    });

    test('Duplicate locations prevented', () {
      List<TargetLocationModel> current = [];
      current = service.addAndFilterLocation(currentLocations: current, newLocation: tirunelveli).updatedLocations;
      final res = service.addAndFilterLocation(currentLocations: current, newLocation: tirunelveli);
      expect(res.updatedLocations.length, 1);
      expect(res.wasAlreadyCovered, isTrue);
    });

    group('Dynamic Nearby Locations Proximity Tests', () {
      test('Nearby locations for Palayamkottai returns local areas sorted by distance', () async {
        final nearby = await service.getNearbyLocationsForReference(referenceLocation: palayamkottai);
        expect(nearby.isNotEmpty, isTrue);
        expect(nearby.any((e) => e.placeId == 'loc_palayamkottai'), isFalse); // Excludes self

        // First nearby items should be very close localities
        final names = nearby.map((e) => e.name).toList();
        expect(names.contains('Samathanapuram') || names.contains('KTC Nagar') || names.contains('Tirunelveli'), isTrue);

        // Verify distance is strictly ascending
        for (int i = 0; i < nearby.length - 1; i++) {
          final d1 = nearby[i].distanceInKm ?? 0.0;
          final d2 = nearby[i + 1].distanceInKm ?? 0.0;
          expect(d1 <= d2, isTrue);
        }
      });

      test('Nearby locations for Tirunelveli returns regional areas', () async {
        final nearby = await service.getNearbyLocationsForReference(referenceLocation: tirunelveli);
        expect(nearby.isNotEmpty, isTrue);
        expect(nearby.any((e) => e.placeId == 'city_tirunelveli'), isFalse);
      });
    });
  });

  group('PostItem Multiple Images Tests', () {
    test('Multiple images stored and ordered correctly on PostItem', () {
      final post = PostItem(
        postId: 'P100',
        businessProfileId: 'BP001',
        bizName: 'ABC Store',
        type: 'offer',
        title: 'Special Offer',
        subtitle: 'ABC Store • Tirunelveli',
        description: 'Great discounts on products.',
        timeAgo: 'Just now',
        images: [
          '/data/user/0/app/cache/img1.jpg',
          '/data/user/0/app/cache/img2.jpg',
          '/data/user/0/app/cache/img3.jpg',
        ],
      );

      expect(post.images.length, 3);
      expect(post.images[0], '/data/user/0/app/cache/img1.jpg');
      expect(post.images[1], '/data/user/0/app/cache/img2.jpg');
      expect(post.images[2], '/data/user/0/app/cache/img3.jpg');
      expect(post.image, '/data/user/0/app/cache/img1.jpg');
    });

    test('Single image backward compatibility', () {
      final post = PostItem(
        postId: 'P101',
        businessProfileId: 'BP001',
        bizName: 'ABC Store',
        type: 'job',
        title: 'Developer Opening',
        subtitle: 'ABC Store • Madurai',
        description: 'Hiring Flutter developer.',
        timeAgo: 'Just now',
        image: 'https://example.com/banner.jpg',
      );

      expect(post.images.length, 1);
      expect(post.images.first, 'https://example.com/banner.jpg');
      expect(post.image, 'https://example.com/banner.jpg');
    });

    test('Empty images list handled gracefully', () {
      final post = PostItem(
        postId: 'P102',
        businessProfileId: 'BP002',
        bizName: 'Tech Co',
        type: 'job',
        title: 'Manager Needed',
        subtitle: 'Tech Co • Chennai',
        description: 'Office manager position.',
        timeAgo: 'Just now',
      );

      expect(post.images, isEmpty);
      expect(post.image, isNull);
    });
  });
}

