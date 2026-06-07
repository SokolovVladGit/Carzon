import 'package:flutter/material.dart';

import '../../../sellers/presentation/widgets/public_seller_name_section.dart';
import 'profile_grouped_card.dart';

class ProfileSellerIdentitySection extends StatelessWidget {
  const ProfileSellerIdentitySection({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ProfileGroupedCard(
      title: title,
      subtitle: subtitle,
      childPadding: const EdgeInsets.only(bottom: 2),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: PublicSellerNameSection(embeddedInSection: true),
      ),
    );
  }
}
