import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';

/// Create-only quiet contact disclosure. Edit keeps [PublicContactNotice].
class CreateListingContactNotice extends StatelessWidget {
  const CreateListingContactNotice({super.key});

  static const testKey = ValueKey('create_listing_contact_notice');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final fg = cs.onSurfaceVariant.withValues(alpha: light ? 0.72 : 0.80);

    return Padding(
      key: testKey,
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(CarzonIcons.info, size: 16, color: fg),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.createListingContactNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: fg,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
