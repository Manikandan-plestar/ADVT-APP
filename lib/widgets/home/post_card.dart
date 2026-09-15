import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import 'job_card.dart';
import 'offer_card.dart';

class PostCard extends StatelessWidget {
  final PostItem item;
  final VoidCallback onView;
  final VoidCallback onToggleSave;

  const PostCard({
    super.key,
    required this.item,
    required this.onView,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    if (item.type == 'job') {
      return JobCard(item: item, onView: onView, onToggleSave: onToggleSave);
    } else {
      return OfferCard(item: item, onView: onView, onToggleSave: onToggleSave);
    }
  }
}
